#!/bin/sh
set -e

mkdir -p /app/pb_hooks

# Create a PocketBase JS hook that:
# 1. Serves the PBCONSOLE_URL via API endpoint (for logo redirect)
# 2. Auto-sets the Application name from APP_NAME env var on startup
cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
// Serve PBConsole redirect URL
routerAdd("GET", "/api/pbconsole-url", (e) => {
    const url = $os.getenv("PBCONSOLE_URL")
    return e.json(200, { "url": url || "" })
})

// Auto-set Application name from APP_NAME env var on first boot
onBootstrap((e) => {
    const appName = $os.getenv("APP_NAME")
    if (!appName) return

    const settings = e.app.settings()
    // Only set if still default "Acme" or empty
    if (settings.meta.appName === "Acme" || !settings.meta.appName) {
        settings.meta.appName = appName
        e.app.save(settings)
    }
})
HOOKEOF

exec "$@"
