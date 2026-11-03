#!/bin/bash

# خواندن پورت‌ها از متغیرهای Railway (یا استفاده از مقادیر پیش‌فرض)
MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}
MY_TUNNEL_PORT=${TUNNEL_PORT:-8080}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیم یوزرنیم و پسورد روی admin
./x-ui setting -username admin -password admin

# تنظیم مسیر اصلی، پورت پنل و پورت ساب از طریق دیتابیس
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui (Panel Port: ${MY_PANEL_PORT} | Sub Port: ${MY_SUB_PORT}) in Background..."
./x-ui &

echo "Container is running. Open Railway Terminal to configure C-Tunnel on Port: ${MY_TUNNEL_PORT}"
# جلوگیری از بسته شدن کانتینر
tail -f /dev/null
