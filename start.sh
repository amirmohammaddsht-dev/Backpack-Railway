#!/bin/bash

# خواندن متغیرها از Railway
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}
MY_TUNNEL_PORT=${TUNNEL_PORT:-8080}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیمات پایه پنل و دیتابیس
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel (Port: ${MY_PANEL_PORT})..."
./x-ui &

cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    echo "==========================================================="
    echo "Manual Mode Active: No TUNNEL_LINK variable found."
    echo "Railway Port is routed to C-Tunnel on port ${MY_TUNNEL_PORT}."
    echo "==========================================================="
    tail -f /dev/null
else
    echo "==========================================================="
    echo "Auto Mode Active: Starting C-Tunnel Engine directly."
    echo "==========================================================="
    
    # فراخوانی C-Tunnel برای استخراج و اجرای کانفیگ
    ctunnel apply-link "$TUNNEL_LINK"
    
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Running Tunnel Engine..."
        eval "$EXEC_CMD"
        
        echo "Tunnel engine stopped! Container will stay alive for Panel access."
        tail -f /dev/null
    else
        echo "Failed to find generated service file. Container will sleep."
        tail -f /dev/null
    fi
fi
