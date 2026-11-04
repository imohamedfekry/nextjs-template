#!/usr/bin/env bash
# Template self-check: print versions and validate the prepared project.
set -u

echo "== user =="
id
echo "== node =="
node --version
echo "== pnpm =="
pnpm --version
echo "== project =="
cd /home/user/app || exit 1
echo "workdir: $(pwd)"
echo "-- node_modules present: $(test -d node_modules && echo yes || echo NO)"
echo "-- lockfile consistent with package.json:"
pnpm install --frozen-lockfile --reporter=silent >/dev/null 2>&1 && echo "  yes (frozen-lockfile OK)" || echo "  NO (lockfile drift)"
echo "== dev server smoke test =="
/home/user/bin/dev-server.sh start
sleep 6
/home/user/bin/health-check.sh && /home/user/bin/dev-server.sh stop
