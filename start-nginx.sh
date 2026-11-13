#!/bin/sh

# 1. ساخت فایل‌های پایه برای اجرای بدون حافظه
mkdir -p /etc/backpack
if [ ! -f "/etc/backpack/install_path" ]; then
    echo "/root/BackPack" > /etc/backpack/install_path
fi

echo "Waiting for BackPack to initialize..."

MAX_RETRIES=30
RETRY_COUNT=0

# 2. منتظر ماندن برای ساخت فایل تنظیمات
while [ ! -f "/etc/backpack/webui.json" ]; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        break
    fi
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

sleep 2

# 3. استارت کردن اجباری و خودکار پنل وب (بدون نیاز به منوی متنی)
echo "Starting WebUI services..."
/usr/local/bin/systemctl start backpack-webui 2>/dev/null
/usr/local/bin/systemctl start backpack-monitor 2>/dev/null

# 4. استخراج مسیر و رمز عبور
PANEL_PATH=$(grep -oE '"base_path": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')
PANEL_PASS=$(grep -oE '"password": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    # تنظیم Nginx
    sed -i "s|__SECRET_PATH__|$PANEL_PATH|g" /etc/nginx/http.d/default.conf
    
    # چاپ اطلاعات برای شما در لاگ Railway
    echo "============================================="
    echo "🚀 PANEL IS READY (STATELESS MODE)"
    echo "🌐 PATH: /$PANEL_PATH"
    echo "🔑 PASSWORD: $PANEL_PASS"
    echo "============================================="
fi

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"