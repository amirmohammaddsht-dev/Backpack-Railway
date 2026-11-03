#!/bin/bash

# ایجاد مسیر دیتابیس در صورت عدم وجود
mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# تنظیم یوزرنیم و پسورد روی admin
./x-ui setting -username admin -password admin

# حذف مسیر تصادفی پنل (تا سایت مستقیما روی آدرس اصلی باز شود)
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true

echo "Starting 3x-ui Panel..."
./x-ui &

echo "System is ready. Use Railway Console to configure C-Tunnel."
# جلوگیری از بسته شدن کانتینر
tail -f /dev/null
