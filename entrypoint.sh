#!/bin/bash

echo "Starting Initialization for cTunnel-Railway..."
mkdir -p /etc/x-ui

if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."
    x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to ensure port is 2053..."
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

if [ -n "$PORT" ]; then
    echo "Mapping Railway domain (Port $PORT) to Panel (Port 2053) via socat..."
    socat TCP-LISTEN:${PORT},fork,reuseaddr TCP:127.0.0.1:2053 &
fi

if [ -n "$TUNNEL_LINK" ]; then
    echo "$TUNNEL_LINK" > /opt/backpack/tunnel_link.txt
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
