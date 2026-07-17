#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
GAME_LIST="$MODDIR/config/games.list"
list_games(){ grep -v '^[[:space:]]*#' "$GAME_LIST" 2>/dev/null | sed '/^[[:space:]]*$/d'; }
valid_pkg(){ printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$'; }
add_game(){ valid_pkg "$1" || { echo "Invalid package name" >&2; return 2; }; grep -qxF "$1" "$GAME_LIST" 2>/dev/null || printf '%s\n' "$1" >> "$GAME_LIST"; echo "Added $1"; }
remove_game(){ tmp="$GAME_LIST.tmp"; grep -vxF "$1" "$GAME_LIST" > "$tmp" 2>/dev/null || true; mv "$tmp" "$GAME_LIST"; echo "Removed $1"; }
launch_game(){ valid_pkg "$1" || { echo "Invalid package name" >&2; return 2; }; monkey -p "$1" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 && echo "Launched $1" || { echo "Unable to launch $1" >&2; return 1; }; }
stop_game(){ valid_pkg "$1" || { echo "Invalid package name" >&2; return 2; }; am force-stop "$1" >/dev/null 2>&1 && echo "Stopped $1" || return 1; }
set_one_mode(){ mode="$1"; pkg="$2"; valid_pkg "$pkg" || return 2; cmd game mode "$mode" "$pkg" >/dev/null 2>&1 && { log_info "Game Mode $mode: $pkg"; echo "$pkg: $mode"; } || { echo "Game Mode unsupported/failed: $pkg" >&2; return 1; }; }
set_mode(){ mode="$1"; command -v cmd >/dev/null 2>&1 || return 1; list_games | while read -r pkg; do [ -n "$pkg" ] || continue; if cmd game mode "$mode" "$pkg" >/dev/null 2>&1; then log_info "Game Mode $mode: $pkg"; else log_warn "Game Mode unsupported/failed: $pkg"; fi; done; }
case "${1:-list}" in
 list) list_games ;;
 add) [ -n "${2:-}" ] || exit 2; add_game "$2" ;;
 remove) [ -n "${2:-}" ] || exit 2; remove_game "$2" ;;
 performance|battery|standard) set_mode "$1" ;;
 launch) [ -n "${2:-}" ] || exit 2; launch_game "$2" ;;
 stop) [ -n "${2:-}" ] || exit 2; stop_game "$2" ;;
 mode) [ -n "${2:-}" ] && [ -n "${3:-}" ] || exit 2; set_one_mode "$2" "$3" ;;
 *) echo "Usage: game.sh {list|add <pkg>|remove <pkg>|launch <pkg>|stop <pkg>|mode <performance|battery|standard> <pkg>|performance|battery|standard}" >&2; exit 2;;
esac
