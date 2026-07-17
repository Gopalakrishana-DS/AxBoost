#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/capabilities.sh" >/dev/null 2>&1

probe_write_setting() {
  ns="$1"; key="$2"
  old="$(settings get "$ns" "$key" 2>/dev/null)"
  [ -n "$old" ] || return 1
  [ "$old" != "null" ] || return 1
  settings put "$ns" "$key" "$old" >/dev/null 2>&1
}

classify() {
  label="$1"; state="$2"; reason="$3"
  printf '%-28s %-13s %s\n' "$label" "$state" "$reason"
}

printf 'AxBoost compatibility report\n'
printf '%s\n' '--------------------------------------------------------------------------'
printf 'Device: %s (%s)\n' "$(safe_getprop ro.product.model)" "$(safe_getprop ro.product.device)"
printf 'Android: %s / API %s\n' "$(safe_getprop ro.build.version.release)" "$(safe_getprop ro.build.version.sdk)"
printf 'ROM: %s%s\n' "$(safe_getprop ro.mi.os.version.name)" "$(safe_getprop ro.miui.ui.version.name)"
printf 'SoC: %s\n\n' "$(get_soc_name)"

if probe_write_setting global window_animation_scale; then classify 'Animation controls' Stable 'Readable and writable through Android settings'; else classify 'Animation controls' Unsupported 'Shell cannot safely verify write access'; fi
if probe_write_setting system peak_refresh_rate; then classify 'Peak refresh request' Stable 'ROM setting is readable and writable'; else classify 'Peak refresh request' Experimental 'Setting may be absent, protected, or ROM-controlled'; fi
if probe_write_setting global disable_window_blurs; then classify 'Window blur control' Stable 'Android global setting is writable'; else classify 'Window blur control' Experimental 'Availability depends on Android build and ROM'; fi
if has_game_service; then classify 'Android Game Mode' Stable 'cmd game service responds'; else classify 'Android Game Mode' Unsupported 'Service unavailable or permission denied'; fi
if cmd power help >/dev/null 2>&1; then classify 'Battery Saver control' Stable 'Android power shell service responds'; else classify 'Battery Saver control' Unsupported 'Power shell command unavailable'; fi
if dumpsys thermalservice >/dev/null 2>&1; then classify 'Thermal monitoring' Stable 'Read-only thermal service data available'; else classify 'Thermal monitoring' Experimental 'Thermal service output unavailable'; fi
if dumpsys activity activities >/dev/null 2>&1; then classify 'Foreground app detection' Experimental 'OEM dumpsys formats can differ'; else classify 'Foreground app detection' Unsupported 'Activity service output unavailable'; fi
classify 'CPU/GPU governor writes' Unsupported 'Requires privileged/root interfaces and is outside AxBoost safety policy'
classify 'Thermal limit bypass' Unsupported 'Unsafe and intentionally prohibited'
classify 'V-Sync disable/FPS unlock' Unsupported 'Not a reliable non-root Android API'
