#!/bin/sh
set -e

mkdir -p /app/pb_hooks

# Create PocketBase JS hooks that:
# 1. Serve PBCONSOLE_URL and APP_NAME via API endpoint
# 2. Auto-set the Application name from APP_NAME env var
cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
// Serve PBConsole redirect URL and app name
routerAdd("GET", "/api/pbconsole-url", (e) => {
    return e.json(200, {
        "url": $os.getenv("PBCONSOLE_URL") || "",
        "appName": $os.getenv("APP_NAME") || ""
    })
})

// Auto-set Application name when the server starts serving
// (onServe fires after DB is fully initialized, unlike onBootstrap)
onServe((e) => {
    e.next()

    try {
        const appName = $os.getenv("APP_NAME")
        if (!appName) return

        const settings = $app.settings()
        if (settings.meta.appName === "Acme" || !settings.meta.appName) {
            settings.meta.appName = appName
            $app.save(settings)
        }
    } catch(err) {
        // Log but don't crash if settings update fails
        console.log("PBConsole: could not set app name:", err)
    }
})
HOOKEOF

exec "$@"
