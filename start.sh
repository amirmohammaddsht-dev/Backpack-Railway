#!/bin/bash

# خواندن پورت‌ها از متغیرهای Railway (در صورت عدم وجود، مقادیر پیش‌فرض اعمال می‌شود)
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}

# ==========================================
# 1. Setup and Start 3x-ui Panel
# ==========================================
mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیم یوزرنیم و پسورد پنل روی admin
./x-ui setting -username admin -password admin

# به‌روزرسانی پورت‌ها و حذف مسیر تصادفی پنل در دیتابیس
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel on port ${MY_PANEL_PORT}..."
./x-ui &

# ==========================================
# 2. Setup and Start C-Tunnel Engine
# ==========================================
cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    # حالت دستی: اگر متغیر TUNNEL_LINK تنظیم نشده باشد
    echo "==========================================================="
    echo "Manual Mode Active: No TUNNEL_LINK variable found."
    echo "Open Railway Terminal to test and configure C-Tunnel."
    echo "==========================================================="
    tail -f /dev/null
else
    # حالت اتوماتیک: اجرای مستقیم هسته تانل از روی لینک
    echo "==========================================================="
    echo "Auto Mode Active: Starting C-Tunnel Engine directly."
    echo "==========================================================="
    
    # دور زدن محدودیت داکر با ساخت فایل fake systemctl
    cat << 'EOF' > /usr/bin/systemctl
#!/bin/sh
echo "Fake systemctl called: $@"
exit 0
EOF
    chmod +x /usr/bin/systemctl
    
    # اعمال لینک تانل برای تولید فایل کانفیگ
    ./c-tunnel apply-link "$TUNNEL_LINK"
    
    echo "Extracting background engine command..."
    # پیدا کردن فایل کانفیگ ساخته شده
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        # استخراج دستور اجرایی اصلی از فایل سرویس
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Running extracted command: $EXEC_CMD"
        
        # اجرای هسته پردازشی تانل در خط جلو
        eval "$EXEC_CMD"
        
        # در صورت متوقف شدن تانل، کانتینر برای کار با پنل روشن می‌ماند
        echo "Tunnel engine stopped unexpectedly! Keeping container alive for Panel..."
        tail -f /dev/null
    else
        echo "Failed to find generated service file. Container will sleep to allow debugging."
        tail -f /dev/null
    fi
fi
