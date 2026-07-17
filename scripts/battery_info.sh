#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

read_numeric_file() {
  f="$1"
  [ -r "$f" ] || return 1
  v="$(cat "$f" 2>/dev/null | tr -d '\r' | sed -n '1p')"
  v="$(trim "$v")"
  case "$v" in ''|*[!0-9.-]*) return 1 ;; esac
  printf '%s\n' "$v"
}

first_numeric_path() {
  for f in "$@"; do
    v="$(read_numeric_file "$f" 2>/dev/null)" || continue
    printf '%s|%s\n' "$v" "$f"
    return 0
  done
  return 1
}

battery_dump_field() {
  key="$1"
  dumpsys battery 2>/dev/null | awk -F: -v k="$key" '
    {left=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", left)}
    tolower(left)==tolower(k) {val=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); print val; exit}'
}

health_label() {
  raw="$(battery_dump_field health)"
  case "$raw" in
    1) echo "Unknown" ;;
    2) echo "Good" ;;
    3) echo "Overheat" ;;
    4) echo "Dead" ;;
    5) echo "Over-voltage" ;;
    6) echo "Unspecified failure" ;;
    7) echo "Cold" ;;
    ''|null) echo "Unknown" ;;
    *) echo "$raw" ;;
  esac
}

cycle_count() {
  # Android 14+ may expose this through ACTION_BATTERY_CHANGED / dumpsys.
  for key in "cycle count" cycle_count cycleCount; do
    v="$(battery_dump_field "$key")"
    case "$v" in ''|*[!0-9]*) ;; *) printf '%s|dumpsys battery\n' "$v"; return 0 ;; esac
  done

  # Common OEM/Qualcomm sysfs locations. Accept only a single scalar value;
  # some devices expose bucketed cycle statistics which must not be summed.
  for f in \
    /sys/class/power_supply/battery/cycle_count \
    /sys/class/power_supply/bms/cycle_count \
    /sys/class/power_supply/battery/battery_cycle \
    /sys/class/power_supply/bms/battery_cycle \
    /sys/class/power_supply/battery/cycle \
    /sys/class/power_supply/bms/cycle; do
    [ -r "$f" ] || continue
    raw="$(cat "$f" 2>/dev/null | tr -d '\r' | sed -n '1p' | xargs)"
    case "$raw" in ''|*[!0-9]*) continue ;; esac
    printf '%s|%s\n' "$raw" "$f"
    return 0
  done
  return 1
}

soh_direct() {
  for f in \
    /sys/class/power_supply/battery/soh \
    /sys/class/power_supply/bms/soh \
    /sys/class/power_supply/battery/state_of_health \
    /sys/class/power_supply/bms/state_of_health \
    /sys/class/power_supply/battery/capacity_soh \
    /sys/class/power_supply/bms/capacity_soh; do
    v="$(read_numeric_file "$f" 2>/dev/null)" || continue
    pct="$(awk -v x="$v" 'BEGIN{if(x>=0 && x<=120) printf "%.0f",x}')"
    [ -n "$pct" ] || continue
    printf '%s|%s|reported\n' "$pct" "$f"
    return 0
  done
  return 1
}

soh_estimated() {
  # Full-charge capacity divided by design capacity. Values must come from
  # the same power-supply node to avoid mixing units or batteries.
  for d in /sys/class/power_supply/battery /sys/class/power_supply/bms; do
    [ -d "$d" ] || continue
    full=""
    design=""
    full_name=""
    design_name=""
    for n in charge_full energy_full; do
      v="$(read_numeric_file "$d/$n" 2>/dev/null)" || continue
      full="$v"; full_name="$n"; break
    done
    for n in charge_full_design energy_full_design; do
      v="$(read_numeric_file "$d/$n" 2>/dev/null)" || continue
      design="$v"; design_name="$n"; break
    done
    [ -n "$full" ] && [ -n "$design" ] || continue
    pct="$(awk -v f="$full" -v d="$design" 'BEGIN{if(d>0){p=(f*100)/d;if(p>=20 && p<=120) printf "%.1f",p}}')"
    [ -n "$pct" ] || continue
    printf '%s|%s/%s,%s|estimated\n' "$pct" "$d" "$full_name" "$design_name"
    return 0
  done
  return 1
}

capacity_values() {
  for d in /sys/class/power_supply/battery /sys/class/power_supply/bms; do
    [ -d "$d" ] || continue
    full=""; design=""; unit=""
    if [ -r "$d/charge_full" ] && [ -r "$d/charge_full_design" ]; then
      full="$(read_numeric_file "$d/charge_full" 2>/dev/null)"
      design="$(read_numeric_file "$d/charge_full_design" 2>/dev/null)"
      unit="uAh"
    elif [ -r "$d/energy_full" ] && [ -r "$d/energy_full_design" ]; then
      full="$(read_numeric_file "$d/energy_full" 2>/dev/null)"
      design="$(read_numeric_file "$d/energy_full_design" 2>/dev/null)"
      unit="uWh"
    fi
    [ -n "$full" ] && [ -n "$design" ] || continue
    if [ "$unit" = "uAh" ]; then
      awk -v f="$full" -v d="$design" 'BEGIN{printf "%.0f / %.0f mAh",f/1000,d/1000}'
    else
      awk -v f="$full" -v d="$design" 'BEGIN{printf "%.0f / %.0f mWh",f/1000,d/1000}'
    fi
    return 0
  done
  echo "Unavailable"
}

cycle="$(cycle_count 2>/dev/null)"
cycle_value="Unavailable"
cycle_source="Not exposed by this ROM/kernel"
if [ -n "$cycle" ]; then
  cycle_value="${cycle%%|*}"
  cycle_source="${cycle#*|}"
fi

soh="$(soh_direct 2>/dev/null)"
[ -n "$soh" ] || soh="$(soh_estimated 2>/dev/null)"
health_value="Unavailable"
health_source="Not exposed by this ROM/kernel"
health_method="unavailable"
if [ -n "$soh" ]; then
  health_value="${soh%%|*}%"
  rest="${soh#*|}"
  health_source="${rest%%|*}"
  health_method="${rest##*|}"
fi

printf 'AxBoost battery information\n'
printf '%s\n' '------------------------------'
printf 'Battery condition: %s\n' "$(health_label)"
printf 'State of health: %s\n' "$health_value"
printf 'Health method: %s\n' "$health_method"
printf 'Full/design capacity: %s\n' "$(capacity_values)"
printf 'Charge cycles: %s\n' "$cycle_value"
printf 'Health source: %s\n' "$health_source"
printf 'Cycle source: %s\n' "$cycle_source"
printf '%s\n' 'Note: Health is reported by the device when available; otherwise it is an estimate from full-charge versus design capacity. Values may be unavailable or vendor-dependent.'
