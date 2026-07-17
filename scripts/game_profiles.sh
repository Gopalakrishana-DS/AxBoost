#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
FILE="$AXBOOST_STATE_DIR/game_profiles.tsv"
ensure_state_dirs || exit 1
valid_pkg(){ printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$'; }
valid_profile(){ case "$1" in gaming|battery|balanced) return 0;; *) return 1;; esac; }
list(){ [ -f "$FILE" ] && cat "$FILE" || true; }
set_profile(){ pkg="$1"; p="$2"; valid_pkg "$pkg" || { echo 'Invalid package name' >&2; return 2; }; valid_profile "$p" || { echo 'Profile must be gaming, battery, or balanced' >&2; return 2; }; tmp="$FILE.tmp"; { [ -f "$FILE" ] && awk -F '\t' -v x="$pkg" '$1!=x' "$FILE"; printf '%s\t%s\n' "$pkg" "$p"; } > "$tmp" && mv "$tmp" "$FILE"; log_info "Per-game profile $pkg=$p"; echo "$pkg: $p"; }
remove(){ pkg="$1"; tmp="$FILE.tmp"; [ -f "$FILE" ] || { echo "No assignment for $pkg"; return 0; }; awk -F '\t' -v x="$pkg" '$1!=x' "$FILE" > "$tmp" && mv "$tmp" "$FILE"; echo "Removed assignment for $pkg"; }
get(){ awk -F '\t' -v x="$1" '$1==x{print $2;exit}' "$FILE" 2>/dev/null; }
apply(){ pkg="$1"; valid_pkg "$pkg" || { echo 'Invalid package name' >&2; return 2; }; p="$(get "$pkg")"; [ -n "$p" ] || { echo "No profile assigned to $pkg" >&2; return 1; }; "$MODDIR/scripts/profile.sh" "$p"; [ "$p" = balanced ] || "$MODDIR/scripts/game.sh" mode "$([ "$p" = gaming ] && echo performance || echo battery)" "$pkg"; }
case "${1:-list}" in list) list;; set) [ "$#" -eq 3 ] || exit 2; set_profile "$2" "$3";; remove) [ "$#" -eq 2 ] || exit 2; remove "$2";; get) [ "$#" -eq 2 ] || exit 2; get "$2";; apply) [ "$#" -eq 2 ] || exit 2; apply "$2";; *) echo 'Usage: game_profiles.sh {list|set <pkg> <gaming|battery|balanced>|remove <pkg>|get <pkg>|apply <pkg>}' >&2; exit 2;; esac
