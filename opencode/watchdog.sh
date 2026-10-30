#!/usr/bin/env bash
set -euo pipefail

BIN="/root/.opencode/bin/opencode"
PORT="${OPENCODE_PORT:-4096}"
POLL="${OPENCODE_WATCH_POLL_SECONDS:-30}"
CHECK="${OPENCODE_WATCH_CHECK_SECONDS:-3600}"
UPDATE_API="${OPENCODE_UPDATE_API:-https://opencode.ai/update/api/latest/cli/npm}"

PID=""
LAST_CHECK=0

log() { echo "[watchdog] $(date '+%F %T') $*"; }

resolve_bin() {
  BIN="$(command -v opencode 2>/dev/null || true)"
  [ -n "$BIN" ] || BIN="/root/.opencode/bin/opencode"
}

semver() {
  grep -Po '\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?' | head -n1
}

version() {
  resolve_bin
  "$BIN" --version 2>/dev/null | semver || true
}

latest() {
  curl -fsSL "$UPDATE_API" 2>/dev/null | grep -Po '"version":"\K[^"]+' | semver || true
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
  log "starting opencode serve (hostname 0.0.0.0, port $PORT)"
  "$BIN" serve --hostname 0.0.0.0 --port "$PORT" &
  PID=$!
}

stop_web() {
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    log "stopping opencode serve (pid $PID)"
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
  PID=""
}

shutdown() {
  log "signal received, shutting down"
  stop_web
  exit 0
}
trap shutdown TERM INT

if [ -z "${OPENCODE_PASSWORD:-}" ]; then
  log "warning: OPENCODE_PASSWORD is not set; opencode generates a random password and prints it to the log"
fi

start_web
LAST="$(version)"
log "current version: ${LAST:-unknown}"

while true; do
  sleep "$POLL"

  if ! web_running; then
    log "serve process exited unexpectedly, restarting"
    stop_web
    start_web
    LAST="$(version)"
    continue
  fi

  NOW="$(date +%s)"
  if [ "$(( NOW - LAST_CHECK ))" -lt "$CHECK" ]; then
    continue
  fi
  LAST_CHECK="$NOW"

  LATEST="$(latest)"
  CUR="$(version)"

  if [ -z "$CUR" ]; then
    log "cannot determine installed version, skip check"
    continue
  fi

  log "check: installed=$CUR running=${LAST:-unknown} latest=${LATEST:-unknown}"

  if [ -n "$LATEST" ] && [ "$LATEST" != "$CUR" ]; then
    log "new version available ($CUR -> $LATEST), upgrading, serve will restart immediately"
    if "$BIN" upgrade; then
      stop_web
      start_web
      LAST="$(version)"
      log "upgrade applied, running version: ${LAST:-unknown}"
    else
      log "opencode upgrade failed, keeping $CUR, will retry next check"
    fi
  elif [ -n "$LAST" ] && [ "$CUR" != "$LAST" ]; then
    log "binary version changed ($LAST -> $CUR), restarting serve to apply"
    stop_web
    start_web
    LAST="$(version)"
  fi
done
