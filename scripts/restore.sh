#!/system/bin/sh
MODDIR=${0%/*}
[ "$(basename "$MODDIR")" = "scripts" ] && MODDIR=${MODDIR%/*}
. "$MODDIR/scripts/common.sh"

restore_all() {
  ensure_state_dirs || return 1

  if [ ! -s "$AXBOOST_CURRENT_BACKUP" ]; then
    echo "No AxBoost settings backup exists."
    log_warn "Restore requested without a backup"
    return 0
  fi

  failed=0
  while IFS="$(printf '\t')" read -r namespace key state encoded; do
    [ -n "$namespace" ] || continue
    case "$state" in
      ABSENT)
        if settings delete "$namespace" "$key" >/dev/null 2>&1; then
          log_info "Restored absence of $namespace/$key"
        else
          log_error "Failed deleting $namespace/$key"
          failed=1
        fi
        ;;
      VALUE)
        value="$(decode_value "$encoded")"
        if settings put "$namespace" "$key" "$value" >/dev/null 2>&1; then
          log_info "Restored $namespace/$key=$value"
        else
          log_error "Failed restoring $namespace/$key"
          failed=1
        fi
        ;;
      *)
        log_error "Invalid backup state for $namespace/$key: $state"
        failed=1
        ;;
    esac
  done < "$AXBOOST_CURRENT_BACKUP"

  if [ "$failed" -eq 0 ]; then
    stamp="$(date '+%Y%m%d-%H%M%S')"
    mv "$AXBOOST_CURRENT_BACKUP" "$AXBOOST_BACKUP_DIR/restored-$stamp.tsv"
    printf '%s\n' "balanced" > "$AXBOOST_PROFILE_FILE"
    echo "AxBoost settings restored successfully."
    return 0
  fi

  echo "Restore completed with errors. Check $AXBOOST_LOG_FILE"
  return 1
}

restore_all
