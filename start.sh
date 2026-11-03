#!/bin/bash

MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel..."
./x-ui &

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
    
    # فراخوانی نسخه جهانی نصب شده
    ctunnel apply-link "$TUNNEL_LINK"
    
    echo "Extracting background engine command..."
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Running extracted command: $EXEC_CMD"
        eval "$EXEC_CMD"
        
        echo "Tunnel engine stopped! Keeping container alive for Panel..."
        tail -f /dev/null
    else
        echo "Failed to find generated service file. Container will sleep."
        tail -f /dev/null
    fi
fi
