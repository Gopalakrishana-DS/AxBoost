#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/scripts/common.sh"

# Restore only values that AxBoost itself backed up.
"$MODDIR/scripts/restore.sh" || log_error "Automatic restore during uninstall failed"
log_info "AxBoost uninstall script completed"
# Logs and archived backups are intentionally retained in /data/local/tmp/axboost
# for troubleshooting. They may be removed manually after confirming restoration.
exit 0
