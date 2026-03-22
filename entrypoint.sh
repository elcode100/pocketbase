#!/bin/sh
set -e

mkdir -p /app/pb_hooks

# Serve PBCONSOLE_URL and APP_NAME via API endpoint (proven to work)
# NO lifecycle hooks — they crash PocketBase
cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
routerAdd("GET", "/api/pbconsole-url", (e) => {
    return e.json(200, {
        "url": $os.getenv("PBCONSOLE_URL") || "",
        "appName": $os.getenv("APP_NAME") || ""
    })
})
HOOKEOF

exec "$@"
