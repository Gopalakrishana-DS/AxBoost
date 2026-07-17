#!/system/bin/sh
MODDIR=${0%/*}
echo "AxBoost v0.7.0"
echo "WebUI: open the WebUI button on the AxBoost plugin card."
echo "1) Status"
echo "2) Apply Gaming"
echo "3) Apply Battery"
echo "4) Restore Balanced"
echo "5) Display controls"
echo "6) Power controls"
echo "7) Battery health"
echo "8) Diagnostic report"
echo "9) Recent log"
echo "0) Exit"
printf 'Choose: '; read -r c
case "$c" in
  1) "$MODDIR/scripts/status.sh" ;;
  2) "$MODDIR/scripts/profile.sh" gaming ;;
  3) "$MODDIR/scripts/profile.sh" battery ;;
  4) "$MODDIR/scripts/profile.sh" balanced ;;
  5) "$MODDIR/scripts/display.sh" status ;;
  6) "$MODDIR/scripts/power.sh" status ;;
  7) "$MODDIR/scripts/battery_info.sh" ;;
  8) "$MODDIR/scripts/report.sh" ;;
  9) "$MODDIR/scripts/compatibility.sh" ;;
  10) "$MODDIR/scripts/benchmark.sh" ;;
  11) tail -n 50 /data/local/tmp/axboost/logs/axboost.log 2>/dev/null ;;
  0) exit 0 ;;
  *) exit 2 ;;
esac
