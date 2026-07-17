#!/system/bin/sh

# Shared paths. Every entry-point must define MODDIR before sourcing this file.
: "${MODDIR:?MODDIR is required}"

AXBOOST_STATE_DIR="/data/local/tmp/axboost"
AXBOOST_LOG_DIR="$AXBOOST_STATE_DIR/logs"
AXBOOST_BACKUP_DIR="$AXBOOST_STATE_DIR/backups"
AXBOOST_CURRENT_BACKUP="$AXBOOST_BACKUP_DIR/settings.tsv"
AXBOOST_PROFILE_FILE="$AXBOOST_STATE_DIR/profile"
AXBOOST_LOG_FILE="$AXBOOST_LOG_DIR/axboost.log"

ensure_state_dirs() {
  mkdir -p "$AXBOOST_LOG_DIR" "$AXBOOST_BACKUP_DIR" || return 1
  chmod 0700 "$AXBOOST_STATE_DIR" "$AXBOOST_LOG_DIR" "$AXBOOST_BACKUP_DIR" 2>/dev/null || true
}

now() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
  ensure_state_dirs || return 1
  printf '[%s] INFO  %s\n' "$(now)" "$*" >> "$AXBOOST_LOG_FILE"
}

log_warn() {
  ensure_state_dirs || return 1
  printf '[%s] WARN  %s\n' "$(now)" "$*" >> "$AXBOOST_LOG_FILE"
}

log_error() {
  ensure_state_dirs || return 1
  printf '[%s] ERROR %s\n' "$(now)" "$*" >> "$AXBOOST_LOG_FILE"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

safe_getprop() {
  getprop "$1" 2>/dev/null | tr -d '\r'
}

setting_exists() {
  namespace="$1"
  key="$2"
  value="$(settings get "$namespace" "$key" 2>/dev/null)"
  [ "$value" != "null" ]
}

read_setting() {
  namespace="$1"
  key="$2"
  settings get "$namespace" "$key" 2>/dev/null
}

# Encode values so tabs/newlines cannot corrupt the TSV backup file.
encode_value() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

decode_value() {
  printf '%s' "$1" | base64 -d 2>/dev/null
}
