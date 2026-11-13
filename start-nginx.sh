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

sleep 2

# روش دوم (پشتیبان قطعی): استخراج مستقیم دستورات از فایل‌های سرویس BackPack
if ! supervisorctl status backpack-webui | grep -q "RUNNING"; then
    echo "Emulator failed. Extracting direct commands from systemd configs..."
    if [ -f "/etc/systemd/system/backpack-webui.service" ]; then
        WEBUI_CMD=$(grep -m 1 '^ExecStart=' /etc/systemd/system/backpack-webui.service | cut -d'=' -f2-)
        eval "$WEBUI_CMD &"
    fi
    if [ -f "/etc/systemd/system/backpack-monitor.service" ]; then
        MONITOR_CMD=$(grep -m 1 '^ExecStart=' /etc/systemd/system/backpack-monitor.service | cut -d'=' -f2-)
        eval "$MONITOR_CMD &"
    fi
fi

sleep 2

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

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"