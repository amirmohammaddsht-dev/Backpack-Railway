#!/bin/bash

echo "Starting Initialization for cTunnel-Railway..."

# ۱. تنظیم پورت پنل ثنایی برای Railway (HTTP Domain)
if [ -n "$PORT" ]; then
    echo "Railway dynamic port detected: $PORT"
    
    # اطمینان از وجود مسیر دیتابیس
    mkdir -p /etc/x-ui
    
    if [ ! -f "/etc/x-ui/x-ui.db" ]; then
        echo "Initializing 3x-ui database on port $PORT..."
        /usr/local/x-ui/x-ui setting -port $PORT
    else
        echo "Updating existing 3x-ui web port to $PORT..."
        sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${PORT}' WHERE key = 'webPort';"
    fi
fi

# ۲. تزریق متغیر TUNNEL_LINK به BackPack
if [ -n "$TUNNEL_LINK" ]; then
    echo "TUNNEL_LINK detected. Configuring BackPack..."
    # کش کردن لینک در یک فایل موقت برای استفاده در Supervisor
    echo "$TUNNEL_LINK" > /opt/backpack/tunnel_link.txt
else
    echo "Warning: TUNNEL_LINK environment variable is not set."
fi

# ۳. اجرای همزمان سرویس‌ها از طریق Supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
