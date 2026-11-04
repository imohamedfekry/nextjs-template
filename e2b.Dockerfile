# Base template for Next.js projects.
#
# Single-stage Dockerfile: multi-stage Dockerfiles are not supported by E2B
# template builds. Base image is the pinned official Node.js LTS image
# (Debian bookworm, /etc/os-release present -> E2B supported family).
#
# Build with the E2B CLI (v2.x):
#   e2b template create <template-name> -c "start command"
#
# Runtime notes:
#   - Default sandbox user `user` (/home/user) is created and given ownership
#     of /home/user by E2B's build system, not by this Dockerfile.
#   - The dev server binds 0.0.0.0:3000 so E2B preview networking can reach it.

FROM node:24.15.0-slim

ARG PNPM_VERSION=10.20.0

# Corepack cache shared with the runtime `user`; pnpm store shared so later
# agent-installed deps reuse the same store.
ENV NODE_ENV=development \
    COREPACK_HOME=/usr/local/share/corepack \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    npm_config_store_dir=/usr/local/share/pnpm-store \
    npm_config_update_notifier=false
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git procps && \
    rm -rf /var/lib/apt/lists/*

RUN corepack enable && \
    corepack prepare pnpm@${PNPM_VERSION} --activate && \
    chmod -R a+rwX /usr/local/share/corepack && \
    pnpm --version && node --version

# E2B's runtime does not propagate image ENV into command execution, so pnpm
# settings are persisted in the global npmrc (read in any environment):
# shared prebuilt store + no update-check noise.
RUN printf "store-dir=/usr/local/share/pnpm-store\nupdate-notifier=false\n" > /usr/local/etc/npmrc && \
    mkdir -p /home/user/.cache/node && \
    cp -a /usr/local/share/corepack /home/user/.cache/node/corepack

WORKDIR /home/user/app

# Dependency layer: only lockfile-driven inputs, so rebuilds are cached.
COPY app/package.json app/pnpm-lock.yaml app/pnpm-workspace.yaml ./

# Build scripts are approved via `pnpm.onlyBuiltDependencies` /
# `allowBuilds` in pnpm-workspace.yaml (sharp, unrs-resolver).
RUN pnpm install --frozen-lockfile

COPY app/ ./

COPY sandbox-scripts/ /home/user/bin/
RUN chmod +x /home/user/bin/*.sh

# E2B creates the runtime `user` (with NOPASSWD sudo, uid != 1000) before the
# builder steps: node_modules, the pnpm store and scripts must be owned/writable
# by it, otherwise a later `pnpm install`/`pnpm add` as `user` detects a
# root-owned modules dir and tries to recreate it (aborts non-interactively).
RUN chown -R user:user /home/user/app /home/user/bin /home/user/.cache && \
    chown -R user:user /usr/local/share/pnpm-store

# Start command (overridable with `e2b template create -c`); the ready command
# confirms the dev server answers HTTP on the dev port.
CMD ["/home/user/bin/dev-server.sh", "start"]
