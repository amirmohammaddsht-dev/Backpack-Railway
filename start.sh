#!/bin/bash

# خواندن پورت‌ها
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_TUNNEL_PORT=${TUNNEL_PORT:-8080}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیمات پنل سنایی
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
    
    # 1. ساخت ابزارهای فیک شبکه برای گول زدن C-Tunnel
    echo "Mocking Kernel Network Tools to bypass TUN requirement..."
    mkdir -p /tmp/fake-net
    for cmd in ip iptables ip6tables sysctl modprobe; do
        cat << EOF > /tmp/fake-net/$cmd
#!/bin/sh
# فیک کردن خروجی موفقیت‌آمیز برای جلوگیری از کرش
exit 0
EOF
        chmod +x /tmp/fake-net/$cmd
    done
    export PATH="/tmp/fake-net:$PATH"

    # 2. خنثی کردن اسکریپت درونی ساخت کارت شبکه C-Tunnel
    mkdir -p /usr/local/lib/ctunnel/
    cat << EOF > /usr/local/lib/ctunnel/ctunnel-kernel
#!/bin/sh
exit 0
EOF
    chmod +x /usr/local/lib/ctunnel/ctunnel-kernel

    # 3. اعمال لینک با محیط فریب‌داده‌شده
    ctunnel apply-link "$TUNNEL_LINK"
    
    # 4. اجرای موتور تانل
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Executing Tunnel Engine without TUN..."
        eval "$EXEC_CMD"
        
        echo "Tunnel engine stopped. Keeping container alive for Panel."
        tail -f /dev/null
    else
        echo "Service file not found."
        tail -f /dev/null
    fi
fi
