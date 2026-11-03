#!/bin/bash

# ==========================================
# 1. Setup and Start 3x-ui Panel
# ==========================================
mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیم یوزرنیم و پسورد روی admin و مسیر اصلی
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true

echo "Starting 3x-ui Panel (Background)..."
./x-ui &

# ==========================================
# 2. Setup and Start C-Tunnel
# ==========================================
cd /app/c-tunnel

# دریافت پورت از Railway (اگر تنظیم نشده باشد 8080 استفاده می‌شود)
LISTEN_PORT=${PORT:-8080}

echo "Starting C-Tunnel Server on port $LISTEN_PORT (Foreground)..."
# اجرای C-Tunnel به عنوان پردازش اصلی برای جلوگیری از بسته شدن کانتینر
./c-tunnel server -l 0.0.0.0:$LISTEN_PORT
