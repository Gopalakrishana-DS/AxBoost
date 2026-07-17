#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/apply.sh" >/dev/null 2>&1
. "$MODDIR/scripts/capabilities.sh" >/dev/null 2>&1
DRY_RUN=0; [ "${1:-}" = --dry-run ] && { DRY_RUN=1; shift; }
PROFILE="${1:-}"
apply_or_plan(){ ns="$1"; key="$2"; val="$3"; why="$4"; if [ "$DRY_RUN" -eq 1 ]; then printf '  %s/%s -> %s (%s)\n' "$ns" "$key" "$val" "$why"; else apply_setting "$ns" "$key" "$val"; fi; }
apply_gaming(){ refresh="$(max_refresh_rate)"; echo "Gaming profile plan:"; [ "$refresh" != unknown ] && apply_or_plan system peak_refresh_rate "$refresh" "highest detected refresh"; apply_or_plan global window_animation_scale 0.5 "faster UI"; apply_or_plan global transition_animation_scale 0.5 "faster UI"; apply_or_plan global animator_duration_scale 0.5 "faster UI"; apply_or_plan global disable_window_blurs 1 "reduce cross-window blur GPU work"; if [ "$DRY_RUN" -eq 0 ]; then "$MODDIR/scripts/game.sh" performance; echo gaming > "$AXBOOST_PROFILE_FILE"; echo "Gaming applied. Thermal limits, V-Sync and CPU/GPU governors were not altered."; fi; }
apply_battery(){ echo "Battery profile plan:"; apply_or_plan system peak_refresh_rate 60 "lower display power"; apply_or_plan global window_animation_scale 0.5 "shorter animations"; apply_or_plan global transition_animation_scale 0.5 "shorter animations"; apply_or_plan global animator_duration_scale 0.5 "shorter animations"; apply_or_plan global disable_window_blurs 1 "reduce blur rendering"; if [ "$DRY_RUN" -eq 0 ]; then "$MODDIR/scripts/game.sh" battery; echo battery > "$AXBOOST_PROFILE_FILE"; echo "Battery profile applied."; fi; }
apply_balanced(){ [ "$DRY_RUN" -eq 1 ] && { echo "Balanced: restore exact backed-up values and set configured games to standard mode."; return; }; "$MODDIR/scripts/restore.sh"; "$MODDIR/scripts/power.sh" restore >/dev/null 2>&1; "$MODDIR/scripts/game.sh" standard; echo balanced > "$AXBOOST_PROFILE_FILE"; }
case "$PROFILE" in gaming) apply_gaming;; battery) apply_battery;; balanced) apply_balanced;; *) echo "Usage: profile.sh [--dry-run] {gaming|battery|balanced}" >&2; exit 2;; esac
