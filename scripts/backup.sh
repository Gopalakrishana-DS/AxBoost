#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

backup_setting() {
  namespace="$1"
  key="$2"
  ensure_state_dirs || return 1

  # Back up each namespace/key only once per backup set.
  if [ -f "$AXBOOST_CURRENT_BACKUP" ] && awk -F '\t' -v n="$namespace" -v k="$key" '$1==n && $2==k {found=1} END {exit !found}' "$AXBOOST_CURRENT_BACKUP"; then
    log_info "Backup already exists for $namespace/$key"
    return 0
  fi

  current="$(read_setting "$namespace" "$key")"
  if [ "$current" = "null" ]; then
    state="ABSENT"
    encoded=""
  else
    state="VALUE"
    encoded="$(encode_value "$current")" || return 1
  fi

  printf '%s\t%s\t%s\t%s\n' "$namespace" "$key" "$state" "$encoded" >> "$AXBOOST_CURRENT_BACKUP" || return 1
  log_info "Backed up $namespace/$key ($state)"
}

if [ "${0##*/}" = "backup.sh" ]; then
  case "${1:-}" in
    setting)
      [ "$#" -eq 3 ] || { echo "Usage: backup.sh setting <namespace> <key>" >&2; exit 2; }
      backup_setting "$2" "$3"
      ;;
    *)
      echo "Usage: backup.sh setting <namespace> <key>" >&2
      exit 2
      ;;
  esac
fi
