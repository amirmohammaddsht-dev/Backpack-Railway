#!/bin/bash
MY_PANEL_PORT=${PANEL_PORT:-2053}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیم یوزر، پسورد، مسیر و پورت پنل
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel on port ${MY_PANEL_PORT} (Background)..."
./x-ui &

echo "Container is running. Open Railway Terminal to configure C-Tunnel."
# جلوگیری از بسته شدن کانتینر
tail -f /dev/null
