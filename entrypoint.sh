```bash
#!/bin/bash

echo "Starting Initialization for Backpack-Railway..."

# --------------------------------------------------
# 1. Initialize 3x-ui database
# --------------------------------------------------

mkdir -p /etc/x-ui

if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."

    cd /app
    ./x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to ensure port is 2053..."

    sqlite3 /etc/x-ui/x-ui.db \
        "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

# --------------------------------------------------
# 2. Configure BackPack Web Panel Base Path
# --------------------------------------------------

echo "Configuring BackPack Web Panel..."

BACKPACK_CONFIG="/etc/backpack/webui.json"
BACKPACK_CONFIG_TMP="${BACKPACK_CONFIG}.tmp"

mkdir -p /etc/backpack

if [ -f "$BACKPACK_CONFIG" ]; then

    echo "Existing BackPack configuration detected..."

    # Validate existing JSON
    if ! jq -e 'type == "object"' "$BACKPACK_CONFIG" >/dev/null 2>&1; then
        echo "ERROR: Invalid BackPack configuration JSON!"
        exit 1
    fi

    # Update only base_path and preserve other settings
    jq '.base_path = "/"' "$BACKPACK_CONFIG" > "$BACKPACK_CONFIG_TMP"

else

    echo "Creating new BackPack configuration..."

    jq -n '{base_path: "/"}' > "$BACKPACK_CONFIG_TMP"

fi

# Apply configuration atomically
chmod 600 "$BACKPACK_CONFIG_TMP"
mv "$BACKPACK_CONFIG_TMP" "$BACKPACK_CONFIG"

echo "BackPack Base Path successfully configured: /"

# --------------------------------------------------
# 3. Configure Railway Port Mapping
# --------------------------------------------------

if [ -n "${PORT:-}" ]; then

    echo "Mapping Railway domain (Port $PORT) to Panel (Port 2053)..."

    socat TCP-LISTEN:${PORT},fork,reuseaddr TCP:127.0.0.1:2053 &

fi

# --------------------------------------------------
# 4. Save BackPack Tunnel Link
# --------------------------------------------------

if [ -n "${TUNNEL_LINK:-}" ]; then

    echo "Saving BackPack Tunnel Link..."

    mkdir -p /opt/backpack

    echo "$TUNNEL_LINK" > /opt/backpack/tunnel_link.txt

fi

# --------------------------------------------------
# 5. Start Supervisor
# --------------------------------------------------

echo "Starting Supervisor..."

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
```