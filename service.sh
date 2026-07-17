#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/scripts/common.sh"

ensure_state_dirs || exit 1
[ -f "$AXBOOST_PROFILE_FILE" ] || printf '%s\n' "balanced" > "$AXBOOST_PROFILE_FILE"
# AxBoost intentionally does not reapply profiles on boot. User action is required.
log_info "AxBoost service initialized; no automatic boot tweaks"
exit 0
