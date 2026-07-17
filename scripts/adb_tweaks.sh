#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/apply.sh" >/dev/null 2>&1

usage(){ echo "Usage: adb_tweaks.sh {list|status|apply <id>|pack <responsive|battery|quiet|privacy>|restore}" >&2; }
row(){ printf '%-24s %-8s %s\n' "$1" "$2" "$3"; }
get_spec(){
  case "$1" in
    anim_fast) echo 'global|window_animation_scale|0.5|Faster window animations' ;;
    transition_fast) echo 'global|transition_animation_scale|0.5|Faster transition animations' ;;
    animator_fast) echo 'global|animator_duration_scale|0.5|Faster animator duration' ;;
    blur_off) echo 'global|disable_window_blurs|1|Disable cross-window blur' ;;
    mobile_data_idle_off) echo 'global|mobile_data_always_on|0|Stop keeping mobile data active while Wi-Fi is connected' ;;
    wifi_scan_off) echo 'global|wifi_scan_always_enabled|0|Disable Wi-Fi scanning when Wi-Fi is off' ;;
    ble_scan_off) echo 'global|ble_scan_always_enabled|0|Disable Bluetooth scanning when Bluetooth is off' ;;
    wifi_wakeup_off) echo 'global|wifi_wakeup_enabled|0|Disable automatic Wi-Fi wake-up' ;;
    adaptive_battery_on) echo 'global|adaptive_battery_management_enabled|1|Enable Android adaptive battery management' ;;
    app_standby_on) echo 'global|app_standby_enabled|1|Enable Android app standby' ;;
    cached_freezer_on) echo 'global|cached_apps_freezer|enabled|Enable cached-app freezer when supported' ;;
    haptics_off) echo 'system|haptic_feedback_enabled|0|Disable touch haptic feedback' ;;
    sounds_off) echo 'system|sound_effects_enabled|0|Disable UI sound effects' ;;
    lock_sounds_off) echo 'system|lockscreen_sounds_enabled|0|Disable lock-screen sounds' ;;
    verifier_on) echo 'global|package_verifier_enable|1|Keep Android package verification enabled' ;;
    adb_verify_on) echo 'global|verifier_verify_adb_installs|1|Verify apps installed through ADB' ;;
    *) return 1;;
  esac
}
ids(){ echo 'anim_fast transition_fast animator_fast blur_off mobile_data_idle_off wifi_scan_off ble_scan_off wifi_wakeup_off adaptive_battery_on app_standby_on cached_freezer_on haptics_off sounds_off lock_sounds_off verifier_on adb_verify_on'; }
list(){
  echo 'HyperOS 2 / Android ADB tweak catalog'; echo '------------------------------------------------------------'
  for id in $(ids); do IFS='|' read -r ns key val desc <<EOF2
$(get_spec "$id")
EOF2
    row "$id" "$ns" "$desc"
  done
  echo; echo 'All entries use Android SettingsProvider. ROM behavior is verified by read-back, but some effects remain device-dependent.'
}
status(){
  echo 'ADB tweak status'; echo '------------------------------------------------------------'
  for id in $(ids); do IFS='|' read -r ns key target desc <<EOF2
$(get_spec "$id")
EOF2
    current="$(settings get "$ns" "$key" 2>/dev/null)"; [ "$current" = null ] && current=unset
    [ "$current" = "$target" ] && state=ACTIVE || state="$current"
    printf '%-24s %s\n' "$id" "$state"
  done
}
apply_one(){
  id="$1"; spec="$(get_spec "$id")" || { echo "Unknown tweak: $id" >&2; return 2; }
  IFS='|' read -r ns key val desc <<EOF2
$spec
EOF2
  apply_setting "$ns" "$key" "$val" || return 1
  got="$(settings get "$ns" "$key" 2>/dev/null)"
  if [ "$got" = "$val" ]; then echo "Applied: $id — $desc"; return 0; fi
  echo "Write was not retained: $id ($ns/$key read back as $got)" >&2; return 1
}
pack(){
  case "$1" in
    responsive) set='anim_fast transition_fast animator_fast blur_off' ;;
    battery) set='mobile_data_idle_off wifi_scan_off ble_scan_off wifi_wakeup_off adaptive_battery_on app_standby_on cached_freezer_on' ;;
    quiet) set='haptics_off sounds_off lock_sounds_off' ;;
    privacy) set='verifier_on adb_verify_on wifi_scan_off ble_scan_off' ;;
    *) usage; return 2;;
  esac
  failed=0; for id in $set; do apply_one "$id" || failed=1; done
  [ "$failed" -eq 0 ] && echo "Pack applied: $1" || { echo "Pack completed with unsupported/failed entries." >&2; return 1; }
}
case "${1:-list}" in
 list) list;; status) status;; apply) [ -n "${2:-}" ] || { usage; exit 2; }; apply_one "$2";; pack) [ -n "${2:-}" ] || { usage; exit 2; }; pack "$2";; restore) exec "$MODDIR/scripts/restore.sh";; *) usage; exit 2;; esac
