#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/detect.sh" >/dev/null 2>&1

supports_setting() {
  namespace="$1"
  key="$2"
  case "$namespace" in system|secure|global) ;; *) return 2 ;; esac
  settings get "$namespace" "$key" >/dev/null 2>&1
}

max_refresh_rate() {
  # Prefer the ROM-configured peak. POCO/HyperOS commonly exposes 120 here.
  rate="$(settings get system peak_refresh_rate 2>/dev/null)"
  case "$rate" in
    ''|null|*[!0-9.]*) rate="" ;;
  esac

  if [ -z "$rate" ]; then
    # Fallback: parse SurfaceFlinger/display output and choose the largest Hz value.
    rate="$(dumpsys display 2>/dev/null | awk '
      {
        line=$0
        while (match(line, /[0-9]+([.][0-9]+)?[[:space:]]*Hz/)) {
          value=substr(line, RSTART, RLENGTH)
          gsub(/[[:space:]]*Hz/, "", value)
          if ((value + 0) > max) max=value + 0
          line=substr(line, RSTART + RLENGTH)
        }
      }
      END { if (max > 0) printf "%g\n", max }
    ')"
  fi

  [ -n "$rate" ] && printf '%s\n' "$rate" || printf '%s\n' "unknown"
}

has_game_service() {
  cmd game help >/dev/null 2>&1 || cmd game list-modes android >/dev/null 2>&1
}

is_hyperos_or_miui() {
  [ -n "$(safe_getprop ro.mi.os.version.name)" ] || [ -n "$(safe_getprop ro.miui.ui.version.name)" ]
}

print_capabilities() {
  printf 'AxBoost capabilities\n'
  printf '%s\n' '------------------------------'
  printf 'Maximum/configured refresh: %s Hz\n' "$(max_refresh_rate)"
  if supports_setting system peak_refresh_rate; then printf 'peak_refresh_rate setting: available\n'; else printf 'peak_refresh_rate setting: unavailable\n'; fi
  if supports_setting system min_refresh_rate; then printf 'min_refresh_rate setting: available\n'; else printf 'min_refresh_rate setting: unavailable\n'; fi
  if supports_setting global window_animation_scale; then printf 'animation settings: available\n'; else printf 'animation settings: unavailable\n'; fi
  if has_game_service; then printf 'Android game service: available\n'; else printf 'Android game service: unavailable/permission denied\n'; fi
  if is_hyperos_or_miui; then printf 'ROM family: HyperOS/MIUI\n'; else printf 'ROM family: other Android\n'; fi
}

if [ "${0##*/}" = "capabilities.sh" ]; then
  print_capabilities
fi
