#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

get_soc_name() {
  soc="$(safe_getprop ro.soc.model)"
  [ -n "$soc" ] || soc="$(safe_getprop ro.board.platform)"
  [ -n "$soc" ] || soc="unknown"
  printf '%s\n' "$soc"
}

get_rom_name() {
  if [ -n "$(safe_getprop ro.mi.os.version.name)" ] || [ -n "$(safe_getprop ro.miui.ui.version.name)" ]; then
    printf '%s\n' "HyperOS/MIUI"
  else
    value="$(safe_getprop ro.build.version.incremental)"
    [ -n "$value" ] && printf '%s\n' "$value" || printf '%s\n' "Android"
  fi
}

get_total_ram_mb() {
  awk '/MemTotal:/ { printf "%d\n", $2 / 1024; exit }' /proc/meminfo 2>/dev/null
}

get_current_refresh_rate() {
  rate="$(settings get system peak_refresh_rate 2>/dev/null)"
  [ "$rate" != "null" ] && [ -n "$rate" ] && printf '%s\n' "$rate" || printf '%s\n' "auto/unknown"
}

print_device_info() {
  printf 'Brand: %s\n' "$(safe_getprop ro.product.brand)"
  printf 'Manufacturer: %s\n' "$(safe_getprop ro.product.manufacturer)"
  printf 'Model: %s\n' "$(safe_getprop ro.product.model)"
  printf 'Device: %s\n' "$(safe_getprop ro.product.device)"
  printf 'Android: %s (API %s)\n' "$(safe_getprop ro.build.version.release)" "$(safe_getprop ro.build.version.sdk)"
  printf 'ROM: %s\n' "$(get_rom_name)"
  printf 'SoC: %s\n' "$(get_soc_name)"
  printf 'ABI: %s\n' "$(safe_getprop ro.product.cpu.abi)"
  printf 'RAM: %s MB\n' "$(get_total_ram_mb)"
  printf 'Configured peak refresh: %s Hz\n' "$(get_current_refresh_rate)"
  printf 'AxManager environment: %s\n' "${AXERON:-unknown}"
}

if [ "${0##*/}" = "detect.sh" ]; then
  print_device_info
fi
