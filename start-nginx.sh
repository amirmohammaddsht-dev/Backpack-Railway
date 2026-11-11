#!/bin/sh

echo "Waiting for BackPack to initialize and create config files..."

MAX_RETRIES=30
RETRY_COUNT=0

# صبر کردن تا زمانی که فایل webui.json ساخته شود
while [ ! -f "/etc/backpack/webui.json" ]; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "Timeout: BackPack config files were not created after 60 seconds."
        break
    fi
    echo "Still waiting for /etc/backpack/webui.json... (Attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

echo "BackPack files detected! Proceeding to extract panel path..."
sleep 2

# استخراج دقیق base_path از فایل webui.json
PANEL_PATH=$(grep -E '"base_path": *"[^"]+"' /etc/backpack/webui.json 2>/dev/null | awk -F'"' '{print $4}')

if [ -n "$PANEL_PATH" ]; then
    echo "Successfully detected panel path: $PANEL_PATH"
    
    # جایگذاری مسیر در تنظیمات Nginx
    sed -i "s|__SECRET_PATH__|$PANEL_PATH|g" /etc/nginx/http.d/default.conf
    echo "Nginx configured successfully for path: /$PANEL_PATH"
else
    echo "Warning: Could not extract base_path from webui.json."
    echo "--- DEBUG: webui.json Content ---"
    cat /etc/backpack/webui.json 2>/dev/null
    echo "---------------------------------"
fi

echo "Starting Nginx..."
exec /usr/sbin/nginx -g "daemon off;"