#!/bin/bash

# دریافت پورت‌ها از متغیرهای Railway (اگر تنظیم نشده باشند، مقادیر پیش‌فرض اعمال می‌شود)
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_TUNNEL_PORT=${TUNNEL_PORT:-8080}

# ==========================================
# 1. Setup and Start 3x-ui Panel
# ==========================================
mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیم یوزرنیم و پسورد روی admin
./x-ui setting -username admin -password admin

# تنظیم مسیر اصلی و پورت پنل از طریق دیتابیس
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel on port ${MY_PANEL_PORT} (Background)..."
./x-ui &

# ==========================================
# 2. Setup and Start C-Tunnel
# ==========================================
cd /app/c-tunnel

echo "Starting C-Tunnel Server on port ${MY_TUNNEL_PORT} (Foreground)..."
./c-tunnel server -l 0.0.0.0:${MY_TUNNEL_PORT}
