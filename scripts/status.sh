#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/detect.sh" >/dev/null 2>&1
. "$MODDIR/scripts/capabilities.sh" >/dev/null 2>&1

battery_temp() {
  raw="$(dumpsys battery 2>/dev/null | awk -F: '/temperature/ {gsub(/ /,"",$2); print $2; exit}')"
  case "$raw" in ''|*[!0-9-]*) printf '%s\n' "unknown" ;; *) awk -v t="$raw" 'BEGIN { printf "%.1f°C\n", t/10 }' ;; esac
}

available_ram_mb() {
  awk '/MemAvailable:/ { printf "%d MB\n", $2 / 1024; exit }' /proc/meminfo 2>/dev/null
}

profile="balanced"
[ -f "$AXBOOST_PROFILE_FILE" ] && profile="$(cat "$AXBOOST_PROFILE_FILE" 2>/dev/null)"

printf 'AxBoost v0.6.0\n'
printf '%s\n' '------------------------------'
printf 'Profile: %s\n' "$profile"
printf 'Model: %s\n' "$(safe_getprop ro.product.model)"
printf 'Device: %s\n' "$(safe_getprop ro.product.device)"
printf 'Android: %s (API %s)\n' "$(safe_getprop ro.build.version.release)" "$(safe_getprop ro.build.version.sdk)"
printf 'SoC: %s\n' "$(get_soc_name)"
printf 'Battery temperature: %s\n' "$(battery_temp)"
printf 'Available RAM: %s\n' "$(available_ram_mb)"
printf 'Peak refresh setting: %s Hz\n' "$(get_current_refresh_rate)"
printf 'Detected maximum refresh: %s Hz\n' "$(max_refresh_rate)"
if [ -s "$AXBOOST_CURRENT_BACKUP" ]; then printf 'Pending restore entries: %s\n' "$(wc -l < "$AXBOOST_CURRENT_BACKUP" | tr -d ' ')"; else printf 'Pending restore entries: 0\n'; fi
printf 'Log: %s\n' "$AXBOOST_LOG_FILE"
