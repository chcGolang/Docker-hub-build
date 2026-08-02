#!/usr/bin/env bash
set -euo pipefail

BIN="/root/.opencode/bin/opencode"
PORT="${OPENCODE_PORT:-4096}"
POLL="${OPENCODE_WATCH_POLL_SECONDS:-30}"
IDLE_MIN="${OPENCODE_WATCH_IDLE_MINUTES:-30}"
MAX_WAIT_MIN="${OPENCODE_WATCH_MAX_WAIT_MINUTES:-480}"
FORCE_FALLBACK="${OPENCODE_WATCH_FORCE_FALLBACK:-0}"
MAINT_START="${OPENCODE_WATCH_MAINTENANCE_START:-03:00}"
MAINT_END="${OPENCODE_WATCH_MAINTENANCE_END:-04:00}"
STATE_DIR="${OPENCODE_STATE_DIR:-/root/.local/state/opencode}"
PORT_HEX="$(printf '%04x' "$PORT")"

PID=""

log() { echo "[watchdog] $(date '+%F %T') $*"; }

resolve_bin() {
  BIN="$(command -v opencode 2>/dev/null || true)"
  [ -n "$BIN" ] || BIN="/root/.opencode/bin/opencode"
}

version() {
  resolve_bin
  "$BIN" --version 2>/dev/null || true
}

web_running() {
  [ -n "$PID" ] || return 1
  [ -r "/proc/$PID/status" ] || return 1

  local state
  state="$(awk '$1 == "State:" {print $2}' "/proc/$PID/status" 2>/dev/null || true)"
  [ "$state" != "Z" ] && [ "$state" != "X" ]
}

start_web() {
  resolve_bin
  log "starting opencode web (hostname 0.0.0.0, port $PORT)"
  "$BIN" web --hostname 0.0.0.0 --port "$PORT" &
  PID=$!
}

stop_web() {
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    log "stopping opencode web (pid $PID)"
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
  PID=""
}

has_active_connections() {
  local local_addr rem_addr state
  while read -r _ local_addr rem_addr state _; do
    case "$local_addr" in
      *:"$PORT_HEX")
        if [ "$state" = "01" ] && [ "${rem_addr##*:}" != "0000" ]; then
          return 0
        fi
        ;;
    esac
  done < /proc/net/tcp 2>/dev/null
  while read -r _ local_addr rem_addr state _; do
    case "$local_addr" in
      *:"$PORT_HEX")
        if [ "$state" = "01" ] && [ "${rem_addr##*:}" != "0000" ]; then
          return 0
        fi
        ;;
    esac
  done < /proc/net/tcp6 2>/dev/null
  return 1
}

has_recent_state_write() {
  [ -d "$STATE_DIR" ] || return 1

  local recent
  recent="$(find "$STATE_DIR" -type f -mmin "-$IDLE_MIN" -print -quit 2>/dev/null || true)"
  [ -n "$recent" ]
}

is_idle() {
  has_active_connections && return 1
  has_recent_state_write && return 1
  return 0
}

in_maintenance() {
  [ "$FORCE_FALLBACK" = "0" ] && return 1
  local now s e
  now="$(date +%H%M)"
  s="${MAINT_START/:/}"
  e="${MAINT_END/:/}"
  [ "$now" -ge "$s" ] && [ "$now" -lt "$e" ]
}

shutdown() {
  log "signal received, shutting down"
  stop_web
  exit 0
}
trap shutdown TERM INT

start_web
LAST="$(version)"
log "current version: ${LAST:-unknown}"

PENDING=0
PENDING_SINCE=""

while true; do
  sleep "$POLL"

  if ! web_running; then
    log "web process exited unexpectedly, restarting"
    stop_web
    start_web
    LAST="$(version)"
    continue
  fi

  CUR="$(version)"

  if [ "$PENDING" = "0" ] && [ -n "$CUR" ] && [ "$CUR" != "$LAST" ]; then
    log "new version detected: $LAST -> $CUR, waiting for idle before restart"
    PENDING=1
    PENDING_SINCE="$(date +%s)"
  fi

  if [ "$PENDING" = "1" ]; then
    if is_idle; then
      log "idle, restarting web to apply version $CUR"
      stop_web
      start_web
      LAST="$CUR"
      PENDING=0
      PENDING_SINCE=""
    elif in_maintenance && [ "$((( $(date +%s) - PENDING_SINCE ) / 60))" -ge "$MAX_WAIT_MIN" ]; then
      log "pending longer than ${MAX_WAIT_MIN}m, forcing restart in maintenance window"
      stop_web
      start_web
      LAST="$CUR"
      PENDING=0
      PENDING_SINCE=""
    fi
  fi
done
