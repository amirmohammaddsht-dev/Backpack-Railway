#!/bin/bash

echo "Starting Initialization for cTunnel-Railway..."
mkdir -p /etc/x-ui
mkdir -p /etc/backpack

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

# تنظیمات وب‌یوآی بک‌پک برای اجرای روی پورت 2080
export BACKPACK_WEBUI_PORT=2080
export BACKPACK_WEBUI_PATH="/"

# پیکربندی Nginx بر اساس پورت Railway
if [ -n "$PORT" ]; then
    echo "Configuring Nginx on port $PORT..."
    envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
else
    echo "WARNING: PORT environment variable is missing!"
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf