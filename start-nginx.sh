#!/bin/bash

echo "Waiting for BackPack to initialize (10s)..."
# زمان انتظار را کمی بیشتر می‌کنیم تا ساخت فایل‌ها قطعی شود
sleep 10

<<<<<<< HEAD
# استفاده از -a برای خواندن فایل‌های باینری/دیتابیس و جستجوی کلمات کلیدی مختلف
PANEL_PATH=$(grep -airoE '"(path|panel_url|panelpath|base_path)": *"[^"]+"' /etc/backpack/ 2>/dev/null | head -n 1 | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    echo "Successfully detected panel path: $PANEL_PATH"
    CLEAN_PATH=$(echo "$PANEL_PATH" | sed 's/^\///')
    sed -i "s|__SECRET_PATH__|$CLEAN_PATH|g" /etc/nginx/http.d/default.conf
=======
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
>>>>>>> parent of 07cb27a (test for resolving third path address)
else
    echo "Warning: Could not extract panel path. Running DEBUG mode..."
    echo "--- DEBUG: Files in /etc/backpack/ ---"
    ls -la /etc/backpack/
    echo "--- DEBUG: File Contents ---"
    # چاپ محتوای فایل‌ها برای پیدا کردن کلید دقیق
    find /etc/backpack/ -type f -exec echo "File: {}" \; -exec cat {} \; -exec echo "" \;
    echo "--------------------------------------"
fi

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"