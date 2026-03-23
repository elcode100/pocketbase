#!/bin/sh
set -e

mkdir -p /app/pb_hooks

# API hooks: serve PBCONSOLE_URL and current appName
cat > /app/pb_hooks/pbconsole.pb.js << 'HOOKEOF'
routerAdd("GET", "/api/pbconsole-url", (e) => {
    const settings = e.app.settings()
    return e.json(200, {
        "url": $os.getenv("PBCONSOLE_URL") || "",
        "appName": settings.meta.appName || ""
    })
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
