#!/bin/bash

MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیمات پنل
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel..."
./x-ui &

cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    echo "==========================================================="
    echo "Manual Mode Active: No TUNNEL_LINK variable found."
    echo "Open Railway Terminal to test and configure C-Tunnel."
    echo "==========================================================="
    tail -f /dev/null
else
    echo "==========================================================="
    echo "Auto Mode Active: Starting C-Tunnel Engine directly."
    echo "==========================================================="
    
    # ساخت فایل تقلبی systemctl مستقیما در مسیر اصلی سیستم
    cat << 'EOF' > /usr/bin/systemctl
#!/bin/sh
echo "Fake systemctl called: $@"
exit 0
EOF
    chmod +x /usr/bin/systemctl
    
    # اعمال لینک (اکنون بدون ارور systemctl پیش می‌رود و کانفیگ را می‌سازد)
    ./c-tunnel apply-link "$TUNNEL_LINK"
    
    echo "Extracting background engine command..."
    # پیدا کردن کانفیگی که C-Tunnel ساخته است
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        # استخراج دستور اصلی اجرای تانل
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Running extracted command: $EXEC_CMD"
        
        # اجرای هسته تانل در خط جلو
        eval "$EXEC_CMD"
    else
        echo "Failed to find generated service file. Container will sleep to allow debugging."
        tail -f /dev/null
    fi
fi
