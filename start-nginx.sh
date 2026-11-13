#!/bin/sh

# 1. ساخت فایل مسیر حیاتی
mkdir -p /etc/backpack
if [ ! -f "/etc/backpack/install_path" ]; then
    echo "/root/BackPack" > /etc/backpack/install_path
fi

echo "Initializing BackPack in background mode..."

# 2. فراخوانی اولیه سرویس‌ها به کمک شبیه‌سازهای نصب شده
/usr/local/bin/systemctl start backpack
/usr/local/bin/systemctl start backpack-webui
/usr/local/bin/systemctl start backpack-monitor

# 3. اطمینان از ایجاد فایل تنظیمات پنل
MAX_RETRIES=30
RETRY_COUNT=0
while [ ! -f "/etc/backpack/webui.json" ]; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        break
    fi
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

# 4. استخراج اطلاعات پنل
PANEL_PATH=$(grep -oE '"base_path": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')
PANEL_PASS=$(grep -oE '"password": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    # تنظیم مسیر مخفی در Nginx
    sed -i "s|__SECRET_PATH__|$PANEL_PATH|g" /etc/nginx/http.d/default.conf
    
    echo "============================================="
    echo "🚀 PANEL IS READY (STATELESS MODE)"
    echo "🌐 PATH: /$PANEL_PATH"
    echo "🔑 PASSWORD: $PANEL_PASS"
    echo "============================================="
fi

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"