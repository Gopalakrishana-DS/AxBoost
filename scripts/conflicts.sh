#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

PLUGIN_ROOT="/data/user_de/0/com.android.shell/axeron/plugins"
[ -d "$PLUGIN_ROOT" ] || { echo "AxManager plugin directory unavailable"; exit 1; }

scan_one() {
  dir="$1"
  id="$(basename "$dir")"
  [ "$id" = axboost ] && return
  [ -f "$dir/disable" ] && state="disabled" || state="enabled"
  name="$id"
  [ -r "$dir/module.prop" ] && name="$(awk -F= '$1=="name"{sub(/^[^=]*=/,"");print;exit}' "$dir/module.prop")"
  [ -n "$name" ] || name="$id"

  hits=""
  # Text scripts and WebUI only. Native binaries are deliberately not guessed.
  files="$(find "$dir" -type f \( -name '*.sh' -o -name '*.prop' -o -name '*.js' -o -name '*.html' -o -name '*.conf' \) 2>/dev/null)"
  [ -n "$files" ] || return

  grep -Eqs 'peak_refresh_rate|min_refresh_rate' $files 2>/dev/null && hits="${hits}display,"
  grep -Eqs 'window_animation_scale|transition_animation_scale|animator_duration_scale' $files 2>/dev/null && hits="${hits}animations,"
  grep -Eqs 'disable_window_blurs' $files 2>/dev/null && hits="${hits}window_blur,"
  grep -Eqs 'cmd[[:space:]]+game|game_mode' $files 2>/dev/null && hits="${hits}game_mode,"
  grep -Eqs 'thermalservice|thermal[-_ ]|sustained_performance_mode' $files 2>/dev/null && hits="${hits}thermal,"
  grep -Eqs 'force_gpu_rendering|force_4x_msaa|debug\.hwui|debug\.sf\.' $files 2>/dev/null && hits="${hits}graphics_debug,"
  grep -Eqs 'am[[:space:]]+kill|am[[:space:]]+force-stop|kill-all|make-uid-idle|standby-bucket' $files 2>/dev/null && hits="${hits}app_management,"
  grep -Eqs 'device_config[[:space:]]+put.*(activity_manager|runtime_native|game_overlay)' $files 2>/dev/null && hits="${hits}device_config,"

  [ -n "$hits" ] || return
  hits="${hits%,}"
  printf '%s|%s|%s|%s\n' "$id" "$name" "$state" "$hits"
}

printf 'Potential AxBoost overlaps\n'
printf '%s\n' '------------------------------'
found=0
for dir in "$PLUGIN_ROOT"/*; do
  [ -d "$dir" ] || continue
  line="$(scan_one "$dir")"
  [ -n "$line" ] || continue
  found=1
  oldifs="$IFS"; IFS='|'; set -- $line; IFS="$oldifs"
  printf '%s (%s) [%s]\n' "$2" "$1" "$3"
  printf '  Areas: %s\n' "$4"
done
[ "$found" -eq 1 ] || echo 'No readable script-level overlaps detected.'
printf '\nNote: this is a conservative text scan. It cannot inspect native binaries or prove that a detected command is active.\n'
