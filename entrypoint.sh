#!/bin/sh
set -e

# Replace the PBCONSOLE_URL placeholder in the embedded UI assets at runtime.
# This allows each container to have its own dashboard URL without rebuilding the image.
if [ -n "$PBCONSOLE_URL" ]; then
    # The placeholder is embedded in the compiled JS files inside the binary's
    # embedded filesystem, but since we build the UI separately and serve from
    # pb_public, we can sed it there.
    find /app/pb_public -name "*.js" -exec sed -i "s|__PBCONSOLE_URL__|${PBCONSOLE_URL}|g" {} + 2>/dev/null || true
fi

exec "$@"
