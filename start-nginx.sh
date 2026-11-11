#!/bin/sh

echo "Waiting for BackPack to generate panel config..."
sleep 5

# استخراج مسیر با استفاده از grep -E و awk که در BusyBox پشتیبانی می‌شوند
PANEL_PATH=$(grep -roE '"path": *"[^"]+"' /etc/backpack/ 2>/dev/null | head -n 1 | awk -F'"' '{print $4}')

if [ -z "$PANEL_PATH" ]; then
    # تلاش مجدد با کلید panel_url در صورت پیدا نشدن path
    PANEL_PATH=$(grep -roE '"panel_url": *"[^"]+"' /etc/backpack/ 2>/dev/null | head -n 1 | awk -F'"' '{print $4}')
fi

if [ -n "$PANEL_PATH" ]; then
    echo "Successfully detected panel path: $PANEL_PATH"
    # حذف اسلش‌های اضافی در صورت وجود
    CLEAN_PATH=$(echo "$PANEL_PATH" | sed 's/^\///')
    
    # جایگذاری مسیر در تنظیمات Nginx (مسیر http.d مربوط به Alpine)
    sed -i "s|__SECRET_PATH__|$CLEAN_PATH|g" /etc/nginx/http.d/default.conf
else
    echo "Warning: Could not extract panel path. Check /etc/backpack/ structure."
fi

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"