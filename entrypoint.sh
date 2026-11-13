#!/bin/bash

echo "Starting Initialization for Backpack-Railway..."
mkdir -p /etc/x-ui

if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo "Creating new database with admin/admin on port 2053..."
    cd /app && ./x-ui setting -username admin -password admin -port 2053
else
    echo "Updating existing database to ensure port is 2053..."
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2053' WHERE key = 'webPort';"
fi

echo "Services are ready to listen on their native ports."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf