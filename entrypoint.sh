#!/bin/bash

echo "Starting Initialization for Backpack-Railway..."
mkdir -p /etc/x-ui

if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."
    cd /app && ./x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to ensure port is 2053..."
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

echo "Services are ready to listen on their native ports."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

# استخراج مسیر و پسورد جدید برای لاگ Railway
PANEL_PATH=$(grep -oE '"base_path": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')
PANEL_PASS=$(grep -oE '"password": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    sed -i "s|__SECRET_PATH__|$PANEL_PATH|g" /etc/nginx/http.d/default.conf
    
    echo "============================================="
    echo "🚀 PANEL IS READY (STATELESS MODE)"
    echo "🌐 PATH: /$PANEL_PATH"
    echo "🔑 PASSWORD: $PANEL_PASS"
    echo "============================================="
fi