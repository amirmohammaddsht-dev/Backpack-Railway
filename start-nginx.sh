#!/bin/sh

mkdir -p /etc/backpack
if [ ! -f "/etc/backpack/install_path" ]; then
    echo "/root/BackPack" > /etc/backpack/install_path
fi

echo "Waiting for BackPack configuration..."

# 1. منتظر می‌مانیم تا بک‌پک فایل‌های کانفیگ را بسازد
MAX_RETRIES=30
RETRY_COUNT=0
while [ ! -f "/etc/backpack/webui.json" ]; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        break
    fi
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

# 2. اجرای مستقیم فایل‌های پنل در پس‌زمینه (بدون نیاز به systemctl)
echo "Starting WebUI directly..."
/usr/local/bin/backpack-webui &
/usr/local/bin/backpack-monitor &

sleep 2

# 3. استخراج مسیر و پسورد
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

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"