#!/bin/sh
# Starts dsh's Web UI on loopback and Caddy on $PORT in front of it.
set -eu

: "${RAILWAY_PUBLIC_DOMAIN:?set RAILWAY_PUBLIC_DOMAIN (Railway sets it once the service has a public domain)}"

profile_patch="$DSH_HOME/profiles/web/cordis.patch.yml"
if [ ! -e "$profile_patch" ]; then
  mkdir -p "$(dirname "$profile_patch")"
  cp /app/deploy/railway/seed.cordis.patch.yml "$profile_patch"
fi
mkdir -p "$DSH_WORKSPACE"

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

cd "$DSH_WORKSPACE"
exec node /app/apps/cli/lib/bin.js web \
  --no-open \
  --port 3080 \
  --public-url "https://$RAILWAY_PUBLIC_DOMAIN/" \
  --trusted-host "$RAILWAY_PUBLIC_DOMAIN"
