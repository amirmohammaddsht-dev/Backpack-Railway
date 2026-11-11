#!/bin/bash

echo "Waiting for BackPack to generate panel config..."
sleep 5

# جستجوی فایل‌ها برای پیدا کردن آدرس پنل
# معمولا بک‌پک در لاگ‌ها یا کانفیگ خود مسیر را مشخص می‌کند.
# این دستور با فرض وجود "path" یا "panel_url" در فایل‌های تنظیمات نوشته شده است.
# ممکن است نیاز به اصلاح grep بر اساس فرمت دقیق بک‌پک داشته باشید.
PANEL_PATH=$(grep -roP '(?<="path": ")[^"]+' /etc/backpack/ | head -n 1)

if [ -z "$PANEL_PATH" ]; then
    # اگر با "path" پیدا نشد، شاید با "url" ذخیره می‌شود
    PANEL_PATH=$(grep -roP '(?<="panel_url": ")[^"]+' /etc/backpack/ | head -n 1)
fi

if [ -n "$PANEL_PATH" ]; then
    echo "Successfully detected panel path: $PANEL_PATH"
    # حذف اسلش‌های اضافی اگر در متغیر وجود داشت
    CLEAN_PATH=$(echo $PANEL_PATH | sed 's/^\///')
    
    # جایگذاری مسیر در فایل تنظیمات Nginx
sed -i "s|__SECRET_PATH__|$CLEAN_PATH|g" /etc/nginx/http.d/default.conf
else
    echo "Warning: Could not extract panel path. Check /etc/backpack/ structure."
fi

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"