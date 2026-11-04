#!/bin/bash

# خواندن پورت‌ها
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_TUNNEL_PORT=${TUNNEL_PORT:-8080}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# ترمیم خودکار هسته Xray در صورت مخفی شدن توسط Volume
if [ ! -f "bin/xray-linux-amd64" ]; then
    echo "Xray core not found! Downloading automatically..."
    mkdir -p bin
    wget -q -O xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
    unzip -q xray.zip -d xray_temp
    mv xray_temp/xray bin/xray-linux-amd64
    chmod +x bin/xray-linux-amd64
    rm -rf xray.zip xray_temp
fi

./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel on Port: ${MY_PANEL_PORT}..."
./x-ui &

cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    echo "==========================================================="
    echo "Manual Mode Active: Waiting for TUNNEL_LINK variable."
    echo "==========================================================="
    tail -f /dev/null
else
    echo "==========================================================="
    echo "Auto Mode: Starting C-Tunnel in Pure Userspace Mode..."
    echo "==========================================================="
    
    mkdir -p /tmp/fake-net
    for cmd in ip iptables ip6tables sysctl modprobe; do
        cat << EOF > /tmp/fake-net/$cmd
#!/bin/sh
exit 0
EOF
        chmod +x /tmp/fake-net/$cmd
    done
    export PATH="/tmp/fake-net:$PATH"

    mkdir -p /usr/local/lib/ctunnel/
    cat << EOF > /usr/local/lib/ctunnel/ctunnel-kernel
#!/bin/sh
exit 0
EOF
    chmod +x /usr/local/lib/ctunnel/ctunnel-kernel

    ctunnel apply-link "$TUNNEL_LINK"
    
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    if [ -f "$SERVICE_FILE" ]; then
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Executing Tunnel Engine..."
        eval "$EXEC_CMD"
        tail -f /dev/null
    else
        echo "Service file not found."
        tail -f /dev/null
    fi
fi
