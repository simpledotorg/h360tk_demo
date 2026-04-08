#!/usr/bin/env bash
# SFTPGo filesystem action hook (upload). Env vars: https://docs.sftpgo.com/latest/custom-actions/
# SFTPGo clears the container environment for external hooks; use mounted config/sftpgo-ingest.env.
set -euo pipefail

DEFAULT_INGEST_SCRIPT="/scripts/ingest_file_h360tk.py"
INGEST_ENV="${SFTPGO_INGEST_ENV_FILE:-/etc/sftpgo/ingest.env}"
if [[ -f "$INGEST_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$INGEST_ENV"
  set +a
fi

# Outside .upload — bind-mount ./logs/sftpgo-ingest (see docker-compose).
LOG_DIR="${SFTPGO_INGEST_LOG_DIR:-/var/log/sftpgo-ingest}"
LOG_FILE="${LOG_DIR}/ingest-hook.log"
mkdir -p "$LOG_DIR"
log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE" >&2; }

# 1 = success per docs; omit on very old builds
STATUS="${SFTPGO_ACTION_STATUS:-1}"
if [[ "$STATUS" != "1" ]]; then
  log "skip: upload status=${STATUS} (expected 1)"
  exit 0
fi

UPLOADED="${SFTPGO_ACTION_PATH:-${SFTPGO_PATH:-${SFTPGO_EVENT_PATH:-}}}"
if [[ -z "$UPLOADED" ]]; then
  log "skip: no path (SFTPGO_ACTION_PATH unset)"
  exit 0
fi
if [[ ! -f "$UPLOADED" ]]; then
  log "skip: not a file: $UPLOADED"
  exit 0
fi

case "${UPLOADED,,}" in
  *.xlsx|*.xls|*.csv) ;;
  *)
    log "skip: not spreadsheet/csv: $UPLOADED"
    exit 0
    ;;
esac

INGEST_SCRIPT="${INGEST_SCRIPT:-$DEFAULT_INGEST_SCRIPT}"
if [[ ! -f "$INGEST_SCRIPT" ]]; then
  log "ingest script not found: ${INGEST_SCRIPT} (set INGEST_SCRIPT in ${INGEST_ENV})"
  exit 1
fi

log "ingest start: script=$INGEST_SCRIPT action=${SFTPGO_ACTION:-?} path=$UPLOADED size=${SFTPGO_ACTION_FILE_SIZE:-?}"
export PYTHONUNBUFFERED=1
set +e
/opt/ingest/bin/python "$INGEST_SCRIPT" "$UPLOADED" 2>&1 | tee -a "$LOG_FILE" >&2
ec=${PIPESTATUS[0]}
set -e
if [[ "$ec" -eq 0 ]]; then
  log "ingest ok: $UPLOADED"
else
  log "ingest FAILED exit=$ec: $UPLOADED"
  exit "$ec"
fi
