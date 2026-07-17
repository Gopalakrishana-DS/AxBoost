#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

read_battery_field() {
  key="$1"
  dumpsys battery 2>/dev/null | awk -F: -v k="$key" '$1 ~ "^[[:space:]]*" k "[[:space:]]*$" {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}'
}

battery_temp() {
  raw="$(read_battery_field temperature)"
  case "$raw" in ''|*[!0-9-]*) echo unknown ;; *) awk -v t="$raw" 'BEGIN{printf "%.1f°C\n",t/10}' ;; esac
}

battery_current() {
  # current_now is usually microamps and may be negative while discharging.
  for f in /sys/class/power_supply/battery/current_now /sys/class/power_supply/bms/current_now; do
    [ -r "$f" ] || continue
    raw="$(cat "$f" 2>/dev/null)"
    case "$raw" in ''|*[!0-9-]*) continue ;; esac
    awk -v v="$raw" 'BEGIN{printf "%.0f mA\n",v/1000}'
    return
  done
  echo unknown
}

battery_voltage() {
  for f in /sys/class/power_supply/battery/voltage_now /sys/class/power_supply/bms/voltage_now; do
    [ -r "$f" ] || continue
    raw="$(cat "$f" 2>/dev/null)"
    case "$raw" in ''|*[!0-9-]*) continue ;; esac
    awk -v v="$raw" 'BEGIN{printf "%.3f V\n",v/1000000}'
    return
  done
  echo unknown
}

cpu_load() {
  if [ -r /proc/loadavg ]; then
    awk '{printf "%s %s %s\n",$1,$2,$3}' /proc/loadavg
  else
    echo unknown
  fi
}

memory_line() {
  awk '
    /MemTotal:/ {total=$2}
    /MemAvailable:/ {avail=$2}
    END {
      if(total>0){used=total-avail; printf "%.0f/%.0f MB (%.0f%%)\n",used/1024,total/1024,(used*100)/total}
      else print "unknown"
    }' /proc/meminfo 2>/dev/null
}

thermal_status() {
  out="$(dumpsys thermalservice 2>/dev/null)"
  [ -n "$out" ] || { echo unavailable; return; }
  status="$(printf '%s\n' "$out" | awk -F: '/Thermal Status|mStatus/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}')"
  [ -n "$status" ] && echo "$status" || echo available
}

foreground_app() {
  # Multiple fallbacks because OEM dumpsys output differs.
  pkg="$(dumpsys activity activities 2>/dev/null | awk '
    /mResumedActivity|topResumedActivity/ {
      for(i=1;i<=NF;i++) if($i ~ /[A-Za-z0-9_]+\.[A-Za-z0-9_.]+\//){split($i,a,"/"); gsub(/[^A-Za-z0-9_.]/,"",a[1]); print a[1]; exit}
    }')"
  [ -n "$pkg" ] && echo "$pkg" || echo unknown
}

current_refresh() {
  # Prefer active display mode. Fall back to configured peak.
  rate="$(dumpsys display 2>/dev/null | awk '
    /mActiveModeId|activeModeId/ {active=1}
    active && match($0,/[0-9]+([.][0-9]+)?[[:space:]]*Hz/) {v=substr($0,RSTART,RLENGTH); gsub(/[[:space:]]*Hz/,"",v); print v; exit}
  ')"
  [ -n "$rate" ] || rate="$(settings get system peak_refresh_rate 2>/dev/null)"
  case "$rate" in ''|null) echo unknown ;; *) echo "${rate} Hz" ;; esac
}

printf 'AxBoost health\n'
printf '%s\n' '------------------------------'
printf 'Battery level: %s%%\n' "$(read_battery_field level)"
printf 'Battery status: %s\n' "$(read_battery_field status)"
printf 'Battery temperature: %s\n' "$(battery_temp)"
printf 'Battery current: %s\n' "$(battery_current)"
printf 'Battery voltage: %s\n' "$(battery_voltage)"
printf 'CPU load (1/5/15m): %s\n' "$(cpu_load)"
printf 'Memory used: %s\n' "$(memory_line)"
printf 'Current refresh: %s\n' "$(current_refresh)"
printf 'Thermal service: %s\n' "$(thermal_status)"
printf 'Foreground app: %s\n' "$(foreground_app)"
printf '\n'
"$MODDIR/scripts/battery_info.sh"
