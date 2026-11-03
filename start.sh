#!/bin/bash

# دریافت پورت‌ها از متغیرهای داشبورد
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_TUNNEL_PORT=${TUNNEL_PORT:-8080}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیمات دیتابیس پنل
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel on Port: ${MY_PANEL_PORT}..."
./x-ui &

cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    echo "==========================================================="
    echo "Manual Mode Active: Waiting for TUNNEL_LINK variable."
    echo "Domain 1 -> routes to Panel (${MY_PANEL_PORT})"
    echo "Domain 2 -> routes to Tunnel (${MY_TUNNEL_PORT})"
    echo "==========================================================="
    tail -f /dev/null
else
    echo "==========================================================="
    echo "Auto Mode: Starting C-Tunnel Engine..."
    echo "==========================================================="
    
    # اعمال لینک تانل
    ctunnel apply-link "$TUNNEL_LINK"
    
    # پیدا کردن سرویس و اجرای اجباری موتور C-Tunnel
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Executing: $EXEC_CMD"
        eval "$EXEC_CMD"
        
        echo "⚠️ C-Tunnel Engine crashed or stopped! Railway's Kernel is blocking Virtual Interfaces (TUN)."
        echo "Keeping container alive so Panel remains accessible."
        tail -f /dev/null
    else
        echo "Service file not found."
        tail -f /dev/null
    fi
fi
