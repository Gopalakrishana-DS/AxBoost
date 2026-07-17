#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
echo "AxBoost diagnostic report"
echo "Generated: $(date '+%F %T')"
echo
"$MODDIR/scripts/status.sh"
echo
"$MODDIR/scripts/capabilities.sh"
echo
"$MODDIR/scripts/display.sh" status
echo
"$MODDIR/scripts/power.sh" status
echo
"$MODDIR/scripts/health.sh"
echo
"$MODDIR/scripts/battery_info.sh"
echo
"$MODDIR/scripts/conflicts.sh"
