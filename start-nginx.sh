#!/bin/sh

echo "Waiting for BackPack to initialize (10s)..."
# زمان انتظار را کمی بیشتر می‌کنیم تا ساخت فایل‌ها قطعی شود
sleep 10

# استفاده از -a برای خواندن فایل‌های باینری/دیتابیس و جستجوی کلمات کلیدی مختلف
PANEL_PATH=$(grep -airoE '"(path|panel_url|panelpath|base_path)": *"[^"]+"' /etc/backpack/ 2>/dev/null | head -n 1 | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    echo "Successfully detected panel path: $PANEL_PATH"
    CLEAN_PATH=$(echo "$PANEL_PATH" | sed 's/^\///')
    sed -i "s|__SECRET_PATH__|$CLEAN_PATH|g" /etc/nginx/http.d/default.conf
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