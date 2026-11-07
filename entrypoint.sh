#!/bin/bash

echo "Starting Initialization for cTunnel-Railway..."
mkdir -p /etc/x-ui

# قفل کردن پورت وب‌سرور پنل روی 2053
if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."
    cd /app && ./x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to ensure port is 2053..."
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

if [ -n "$TUNNEL_LINK" ]; then
    echo "$TUNNEL_LINK" > /opt/backpack/tunnel_link.txt
fi

echo "Initialization complete. Starting Supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf