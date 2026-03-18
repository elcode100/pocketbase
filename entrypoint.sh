#!/bin/sh
set -e

# Create a PocketBase JS hook that serves the PBCONSOLE_URL via API endpoint.
# This avoids creating pb_public (which causes PocketBase to treat root requests
# as static file lookups, generating hundreds of 404 errors in the logs).
if [ -n "$PBCONSOLE_URL" ]; then
    mkdir -p /app/pb_hooks
    cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
routerAdd("GET", "/api/pbconsole-url", (e) => {
    const url = $os.getenv("PBCONSOLE_URL")
    return e.json(200, { "url": url || "" })
})
HOOKEOF
fi

exec "$@"
