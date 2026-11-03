#!/bin/bash
echo "Starting 3x-ui Panel..."
/usr/local/x-ui/x-ui &

echo "System is ready. Use Railway Console to configure C-Tunnel."
# جلوگیری از بسته شدن کانتینر داکر
tail -f /dev/null