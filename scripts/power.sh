#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
STATE_DIR="$AXBOOST_STATE_DIR/power"; mkdir -p "$STATE_DIR" 2>/dev/null

low_power_state(){ dumpsys power 2>/dev/null | awk -F= '/mLowPowerModeEnabled=/{gsub(/[[:space:]]/,"",$2); print $2; exit}'; }
adaptive_state(){ dumpsys power 2>/dev/null | awk -F= '/mAdaptivePowerSaveEnabled=/{gsub(/[[:space:]]/,"",$2); print $2; exit}'; }
backup_once(){ file="$1"; value="$2"; [ -f "$file" ] || printf '%s\n' "$value" > "$file"; }
set_saver(){
  case "$1" in on) mode=1;; off) mode=0;; *) echo "Use on or off" >&2; return 2;; esac
  old="$(low_power_state)"; [ -n "$old" ] || old=unknown; backup_once "$STATE_DIR/low_power" "$old"
  if cmd power set-mode "$mode" >/dev/null 2>&1; then log_info "Battery Saver set $1"; echo "Battery Saver: $1"; else echo "Battery Saver command failed" >&2; return 1; fi
}
set_adaptive(){
  case "$1" in on) value=true;; off) value=false;; *) echo "Use on or off" >&2; return 2;; esac
  old="$(adaptive_state)"; [ -n "$old" ] || old=unknown; backup_once "$STATE_DIR/adaptive" "$old"
  if cmd power set-adaptive-power-saver-enabled "$value" >/dev/null 2>&1; then log_info "Adaptive Battery Saver set $1"; echo "Adaptive Battery Saver: $1"; else echo "Adaptive Battery Saver unsupported/failed" >&2; return 1; fi
}
restore(){
  if [ -f "$STATE_DIR/low_power" ]; then v="$(cat "$STATE_DIR/low_power")"; case "$v" in true) cmd power set-mode 1 >/dev/null 2>&1;; false) cmd power set-mode 0 >/dev/null 2>&1;; esac; fi
  if [ -f "$STATE_DIR/adaptive" ]; then v="$(cat "$STATE_DIR/adaptive")"; case "$v" in true|false) cmd power set-adaptive-power-saver-enabled "$v" >/dev/null 2>&1;; esac; fi
  rm -rf "$STATE_DIR"; log_info "Power controls restored"; echo "Power controls restored where previous state was readable."
}
status(){ echo "Power controls"; echo "------------------------------"; echo "Battery Saver: $(low_power_state)"; echo "Adaptive Battery Saver: $(adaptive_state)"; }
case "${1:-status}" in status) status;; saver) set_saver "${2:-}";; adaptive) set_adaptive "${2:-}";; restore) restore;; *) echo "Usage: power.sh {status|saver on|off|adaptive on|off|restore}" >&2; exit 2;; esac
