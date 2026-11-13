#!/bin/sh

mkdir -p /etc/backpack
if [ ! -f "/etc/backpack/install_path" ]; then
    echo "/root/BackPack" > /etc/backpack/install_path
fi

echo "Waiting for BackPack configuration..."

MAX_RETRIES=30
RETRY_COUNT=0
while [ ! -f "/etc/backpack/webui.json" ]; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        break
    fi
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

echo "Starting WebUI services..."

# روش اول: اصلاح فرمت ویندوزی (CRLF) فایل شبیه‌ساز و اجرای پنل از طریق آن
if [ -f "/usr/local/bin/systemctl" ]; then
    sed -i 's/\r$//' /usr/local/bin/systemctl
    chmod +x /usr/local/bin/systemctl
    /usr/local/bin/systemctl start backpack-webui 2>/dev/null
    /usr/local/bin/systemctl start backpack-monitor 2>/dev/null
fi

exec /usr/sbin/nginx -g "daemon off;"