#!/usr/bin/env bash
# Manage the Next.js dev server inside the sandbox.
# Usage: dev-server.sh {start|stop|restart|status}
set -u

APP_DIR="/home/user/app"
PID_FILE="/home/user/.dev-server.pid"
LOG_FILE="/home/user/.dev-server.log"
PORT="${DEV_SERVER_PORT:-3000}"

running() {
  [ -f "$PID_FILE" ] && kill -0 "$(sudo cat "$PID_FILE" 2>/dev/null || cat "$PID_FILE")" 2>/dev/null
}

get_pid() { sudo cat "$PID_FILE" 2>/dev/null || cat "$PID_FILE"; }

start() {
  if running; then
    echo "dev server already running (pid $(get_pid))"
    exit 0
  fi
  cd "$APP_DIR"
  # setsid: run in its own process group so stop() can kill the whole tree
  setsid nohup pnpm dev >"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  echo "dev server starting (pid $(get_pid)) on port ${PORT} -- log: ${LOG_FILE}"
}

stop() {
  if running; then
    PID="$(get_pid)"
    # negative pid -> kill the whole process group (pnpm + next)
    kill -TERM -- "-${PID}" 2>/dev/null || kill -TERM "${PID}" 2>/dev/null || true
    sleep 1
    kill -KILL -- "-${PID}" 2>/dev/null || true
    echo "dev server stopped (pid ${PID})"
  else
    echo "dev server not running"
  fi
  rm -f "$PID_FILE"
}

status() {
  if running; then
    echo "dev server running (pid $(get_pid))"
  else
    echo "dev server not running"
  fi
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  restart) stop; start ;;
  status) status ;;
  *) echo "usage: dev-server.sh {start|stop|restart|status}"; exit 1 ;;
esac
