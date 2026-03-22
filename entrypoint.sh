#!/bin/sh
set -e

mkdir -p /app/pb_hooks

# Serve PBCONSOLE_URL via API endpoint (for logo redirect)
cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
routerAdd("GET", "/api/pbconsole-url", (e) => {
    return e.json(200, {
        "url": $os.getenv("PBCONSOLE_URL") || ""
    })
})
HOOKEOF

exec "$@"
