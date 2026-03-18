#!/bin/sh
set -e

# Write the PBConsole dashboard redirect URL to a text file in pb_public.
# The Svelte admin UI fetches this file at runtime to know where to redirect
# when the logo is clicked. This avoids needing to modify the compiled Go binary.
mkdir -p /app/pb_public
if [ -n "$PBCONSOLE_URL" ]; then
    echo "$PBCONSOLE_URL" > /app/pb_public/pbconsole_url.txt
fi

exec "$@"
