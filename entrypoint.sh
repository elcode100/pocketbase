#!/bin/sh
set -e

mkdir -p /app/pb_hooks

# Logo redirect hook (serves PBCONSOLE_URL via API)
cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
routerAdd("GET", "/api/pbconsole-url", (e) => {
    return e.json(200, { "url": $os.getenv("PBCONSOLE_URL") || "" })
})
HOOKEOF

# Hook: when Application name changes in Settings, notify PBConsole webhook
cat > /app/pb_hooks/appname_sync.pb.js << 'HOOKEOF'
onSettingsReload((e) => {
    const pbconsoleUrl = $os.getenv("PBCONSOLE_URL") || ""
    const adminPassword = $os.getenv("ADMIN_PASSWORD") || ""
    const uuid = $os.getenv("SERVICE_UUID") || ""

    if (!pbconsoleUrl || !uuid) return e.next()

    try {
        const settings = e.app.settings()
        const appName = settings.meta.appName || ""
        if (!appName || appName === "Acme") return e.next()

        // Derive PBConsole base URL (strip /dashboard)
        const baseUrl = pbconsoleUrl.replace(/\/dashboard\/?$/, "")

        $http.send({
            url: baseUrl + "/api/pb-webhook",
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                uuid: uuid,
                appName: appName,
                adminPassword: adminPassword
            }),
            timeout: 10
        })
    } catch (err) {
        console.log("appname_sync: failed to notify PBConsole:", err)
    }

    return e.next()
})
HOOKEOF

# Set Application name via PocketBase REST API (runs in background)
# Uses curl to authenticate as superuser and PATCH /api/settings
if [ -n "$APP_NAME" ]; then
  (
    for i in 1 2 3 4 5 6; do
      sleep 5
      # Authenticate as superuser
      AUTH_RESPONSE=$(curl -sf -X POST http://localhost:8080/api/collections/_superusers/auth-with-password \
        -H 'Content-Type: application/json' \
        -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" 2>/dev/null) || continue

      TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
      [ -z "$TOKEN" ] && continue

      # Update Application name in settings
      curl -sf -X PATCH http://localhost:8080/api/settings \
        -H 'Content-Type: application/json' \
        -H "Authorization: $TOKEN" \
        -d "{\"meta\":{\"appName\":\"$APP_NAME\"}}" >/dev/null 2>&1 && break
    done
  ) &
fi

exec "$@"
