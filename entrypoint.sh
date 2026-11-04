#!/bin/bash

echo "Starting Initialization for cTunnel-Railway..."
mkdir -p /etc/x-ui

# تنظیم دیتابیس پنل ثنایی برای اعمال پورت 2053 و یوزر/پسورد admin
if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."
    /usr/local/x-ui/x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to port 2053..."
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

# تزریق لینک تونل
if [ -n "$TUNNEL_LINK" ]; then
    echo "$TUNNEL_LINK" > /opt/backpack/tunnel_link.txt
fi

# اجرای سرویس‌ها
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
