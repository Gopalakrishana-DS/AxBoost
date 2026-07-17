#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/apply.sh" >/dev/null 2>&1
. "$MODDIR/scripts/capabilities.sh" >/dev/null 2>&1

usage(){ echo "Usage: display.sh {status|refresh auto|60|90|120|max|animations off|fast|normal|blur on|off}" >&2; }
refresh(){
  value="$1"
  case "$value" in
    auto)
      backup_setting system peak_refresh_rate || return 1
      settings delete system peak_refresh_rate >/dev/null 2>&1 || return 1
      log_info "Display refresh returned to ROM automatic behavior"
      echo "Refresh preference: automatic"
      ;;
    max) value="$(max_refresh_rate)"; [ "$value" != unknown ] || { echo "Unable to detect maximum refresh" >&2; return 1; }; apply_setting system peak_refresh_rate "$value"; echo "Peak refresh requested: $value Hz" ;;
    60|90|120) apply_setting system peak_refresh_rate "$value"; echo "Peak refresh requested: $value Hz" ;;
    *) usage; return 2;;
  esac
}
animations(){
  case "$1" in off) v=0;; fast) v=0.5;; normal) v=1;; *) usage; return 2;; esac
  apply_setting global window_animation_scale "$v" || return 1
  apply_setting global transition_animation_scale "$v" || return 1
  apply_setting global animator_duration_scale "$v" || return 1
  echo "Animation scale set to $v"
}
blur(){
  case "$1" in off) v=1;; on) v=0;; *) usage; return 2;; esac
  apply_setting global disable_window_blurs "$v" || return 1
  echo "Window blur: $1"
}
status(){
  echo "Display controls"
  echo "------------------------------"
  echo "Peak refresh: $(settings get system peak_refresh_rate 2>/dev/null)"
  echo "Minimum refresh: $(settings get system min_refresh_rate 2>/dev/null)"
  echo "Window animation: $(settings get global window_animation_scale 2>/dev/null)"
  echo "Transition animation: $(settings get global transition_animation_scale 2>/dev/null)"
  echo "Animator duration: $(settings get global animator_duration_scale 2>/dev/null)"
  echo "Window blurs disabled: $(settings get global disable_window_blurs 2>/dev/null)"
}
case "${1:-status}" in status) status;; refresh) refresh "${2:-}";; animations) animations "${2:-}";; blur) blur "${2:-}";; *) usage; exit 2;; esac
