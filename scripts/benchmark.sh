#!/system/bin/sh
MODDIR=${0%/*}; [ "$(basename "$MODDIR")" = scripts ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

OUTDIR="$AXBOOST_STATE_DIR/benchmarks"
mkdir -p "$OUTDIR" 2>/dev/null

cpu_sample() {
  awk 'NR==1{total=0; for(i=2;i<=NF;i++) total+=$i; idle=$5+$6; print total, idle}' /proc/stat
}
mem_available() { awk '/MemAvailable:/{printf "%d",$2/1024;exit}' /proc/meminfo; }
load_avg() { awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null; }

read t1 i1 <<EOF1
$(cpu_sample)
EOF1
sleep 2
read t2 i2 <<EOF2
$(cpu_sample)
EOF2
dt=$((t2-t1)); di=$((i2-i1))
usage="unknown"
[ "$dt" -gt 0 ] && usage="$(awk -v dt="$dt" -v di="$di" 'BEGIN{printf "%.1f%%",((dt-di)*100)/dt}')"

stamp="$(date '+%Y%m%d-%H%M%S')"
file="$OUTDIR/baseline-$stamp.txt"
{
  echo 'AxBoost performance baseline'
  echo '------------------------------'
  echo "Generated: $(date '+%F %T')"
  echo "Profile: $(cat "$AXBOOST_PROFILE_FILE" 2>/dev/null || echo balanced)"
  echo "CPU utilization (2s): $usage"
  echo "Load average (1/5/15m): $(load_avg)"
  echo "Available memory: $(mem_available) MB"
  echo "Thermal status: $(dumpsys thermalservice 2>/dev/null | awk -F: '/Thermal Status|mStatus/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' | sed 's/^$/unavailable/')"
  echo "Battery temperature: $(dumpsys battery 2>/dev/null | awk -F: '/temperature/{gsub(/ /,"",$2); if($2~/^[0-9-]+$/) printf "%.1f C",$2/10; else print "unknown"; exit}')"
  echo "Foreground app: $(dumpsys activity activities 2>/dev/null | awk '/mResumedActivity|topResumedActivity/{for(i=1;i<=NF;i++)if($i~/[A-Za-z0-9_]+\.[A-Za-z0-9_.]+\//){split($i,a,"/");gsub(/[^A-Za-z0-9_.]/,"",a[1]);print a[1];exit}}' | sed 's/^$/unknown/')"
  echo
  echo 'This is a diagnostic baseline, not a synthetic FPS score. Compare runs under similar temperature, battery, and workload conditions.'
} | tee "$file"
log_info "Benchmark baseline saved: $file"
