#!/bin/bash

MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیمات پیش‌فرض پنل
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel..."
./x-ui &

# بخش مدیریت هوشمند C-Tunnel
cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    # اگر لینکی ثبت نشده باشد، کانتینر در حالت آماده‌به‌کار می‌ماند تا دستی تنظیم کنید
    echo "==========================================================="
    echo "Manual Mode Active: No TUNNEL_LINK variable found."
    echo "Open Railway Terminal to test and configure C-Tunnel."
    echo "==========================================================="
    tail -f /dev/null
else
    # اگر لینک ثبت شده باشد، تانل به صورت دائمی و بدون systemctl اجرا می‌شود
    echo "==========================================================="
    echo "Auto Mode Active: Starting C-Tunnel with provided link."
    echo "==========================================================="
    ./c-tunnel apply-link "$TUNNEL_LINK"
fi
