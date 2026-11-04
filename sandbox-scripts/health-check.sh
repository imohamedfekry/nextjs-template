#!/usr/bin/env bash
# Exit 0 when the dev server answers HTTP 200 on its port.
PORT="${DEV_SERVER_PORT:-3000}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/" || true)
if [ "$CODE" = "200" ]; then
  echo "healthy (HTTP ${CODE} on port ${PORT})"
  exit 0
fi
echo "unhealthy (HTTP ${CODE:-none} on port ${PORT})"
exit 1
