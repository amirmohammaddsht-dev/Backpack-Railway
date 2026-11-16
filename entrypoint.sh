#!/bin/bash

echo "Starting Initialization for cTunnel-Railway..."
mkdir -p /etc/x-ui /etc/backpack

if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."
    cd /app && ./x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to ensure port is 2053..."
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

# The tunnel itself is built by the tunnel-setup program (apply-link.sh) once
# supervisord is up, because it needs supervisord to run the tunnel process.
if [ -n "$TUNNEL_LINK" ]; then
    echo "TUNNEL_LINK is set - the tunnel will be built from it."
else
    echo "TUNNEL_LINK is not set - no tunnel will be created."
fi

echo "Services are ready to listen on their native ports."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf