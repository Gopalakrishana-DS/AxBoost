#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"
. "$MODDIR/scripts/backup.sh" >/dev/null 2>&1

apply_setting() {
  namespace="$1"
  key="$2"
  value="$3"

  case "$namespace" in
    system|secure|global) ;;
    *) log_error "Invalid settings namespace: $namespace"; return 2 ;;
  esac

  backup_setting "$namespace" "$key" || {
    log_error "Could not back up $namespace/$key"
    return 1
  }

  if settings put "$namespace" "$key" "$value" 2>/dev/null; then
    log_info "Applied $namespace/$key=$value"
    return 0
  fi

  log_error "Failed to apply $namespace/$key=$value"
  return 1
}

case "${1:-}" in
  setting)
    [ "$#" -eq 4 ] || { echo "Usage: apply.sh setting <namespace> <key> <value>" >&2; exit 2; }
    apply_setting "$2" "$3" "$4"
    ;;
  *)
    echo "AxBoost v0.2.0 deliberately contains no optimization profile."
    echo "Developer usage: apply.sh setting <namespace> <key> <value>"
    ;;
esac
