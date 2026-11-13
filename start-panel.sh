#!/bin/sh

mkdir -p /etc/backpack
if [ ! -f "/etc/backpack/install_path" ]; then
    echo "/root/BackPack" > /etc/backpack/install_path
fi

echo "Waiting for BackPack installation to finish..."

# ۱. صبر می‌کنیم تا اسکریپت نصب، فایل اجرایی را دانلود کند
while [ ! -x "/usr/local/bin/backpack" ]; do
    sleep 1
done

# مکث کوتاه برای اطمینان از اتمام کار installer
sleep 2

# ۲. ساخت میان‌برهای اجرایی به صورت دستی (جهت رفع محدودیت Alpine)
ln -sf /usr/local/bin/backpack /usr/local/bin/backpack-webui
ln -sf /usr/local/bin/backpack /usr/local/bin/backpack-monitor

echo "Starting WebUI services directly..."

# ۳. اجرای مستقیم سرویس‌های پنل وب
/usr/local/bin/backpack-webui &
/usr/local/bin/backpack-monitor &

echo "Waiting for WebUI to generate config..."

# ۴. منتظر ماندن برای ساخت فایل کانفیگ توسط وب‌یوآی
MAX_RETRIES=30
RETRY_COUNT=0
while [ ! -f "/etc/backpack/webui.json" ]; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "Timeout waiting for webui.json"
        break
    fi
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

sleep 2

# ۵. استخراج آدرس و پسورد جدید
PANEL_PATH=$(grep -oE '"base_path": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')
PANEL_PASS=$(grep -oE '"password": *"[^"]+"' /etc/backpack/webui.json | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    echo "============================================="
    echo "🚀 PANEL IS READY (STATELESS MODE)"
    echo "🌐 PATH: /$PANEL_PATH"
    echo "🔑 PASSWORD: $PANEL_PASS"
    echo "============================================="
fi

# زنده نگه داشتن اسکریپت برای supervisord
exec tail -f /dev/null