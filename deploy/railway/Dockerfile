# Container image for the Web UI on Railway (or any Docker host).
# Build context is the repository root; railway.json points here.
FROM node:24-bookworm AS build

# C toolchains for the flock/Landlock native addon; git for the install hook.
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential musl-tools python3 git \
  && rm -rf /var/lib/apt/lists/*

ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PUPPETEER_SKIP_DOWNLOAD=1 \
    LEFTHOOK=0 \
    CI=1

RUN corepack enable
WORKDIR /app
COPY . .
RUN pnpm install --frozen-lockfile
# Full native build: also the static Landlock launcher the command sandbox
# falls back to when bubblewrap cannot create namespaces in the container.
RUN pnpm exec tsx native/system/scripts/build.ts
# The build stamps the commit into the UI; the context has no .git, so take
# Railway's commit variable when present; other hosts get a placeholder.
ARG RAILWAY_GIT_COMMIT_SHA=0000000
RUN DSH_CLIENT_COMMIT_HASH="$RAILWAY_GIT_COMMIT_SHA" pnpm run build:artifacts

FROM node:24-bookworm-slim

# git and ripgrep for the agent's shell; bubblewrap for the command sandbox.
RUN apt-get update \
  && apt-get install -y --no-install-recommends git ripgrep bubblewrap ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY --from=caddy:2.10 /usr/bin/caddy /usr/bin/caddy

COPY --from=build /app /app
COPY deploy/railway/Caddyfile /etc/caddy/Caddyfile
COPY deploy/railway/entrypoint.sh /usr/local/bin/dsh-railway
RUN chmod +x /usr/local/bin/dsh-railway

# Mount a persistent volume at /data so sessions, settings, the login cookie
# secret, and the agent's projects survive redeploys. HOME lives there too, so
# the folder picker opens on persistent storage.
ENV HOME=/data/home \
    DSH_HOME=/data/dsh \
    DSH_WORKSPACE=/data/home/projects \
    PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/dsh-railway"]
