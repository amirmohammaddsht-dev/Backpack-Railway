#!/bin/bash
echo "Starting 3x-ui Panel..."
cd /usr/local/x-ui/
./x-ui &

echo "Starting C-Tunnel..."
cd /app/c-tunnel
# دستور اجرای C-Tunnel را در خط زیر وارد کنید. (بسته به زبان آن معمولاً bash یا python است)
# به عنوان مثال:
bash start.sh &
# یا اگر اسکریپت پایتون است: python3 main.py &

# نگه داشتن کانتینر در حالت اجرا و دریافت لاگ‌ها
wait -n
exit $?