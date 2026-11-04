#!/bin/bash

# ذخیره کل دستور پاس داده شده برای لاگ‌گیری دقیق‌تر
echo "[$(date)] systemctl $*" >> /var/log/fake_systemctl.log

COMMAND=$1
shift # رفتن به آرگومان بعدی

# بررسی وجود فلگ --now
START_NOW=false
if [ "$1" == "--now" ]; then
    START_NOW=true
    shift # رفتن به آرگومان بعدی (اسم سرویس)
fi

SERVICE=$1

# اگر سرویسی معرفی نشده بود یا دستور daemon-reload بود، خارج شو
if [ -z "$SERVICE" ] || [ "$COMMAND" == "daemon-reload" ]; then exit 0; fi

SERVICE_NAME=$(basename "$SERVICE" .service)
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# اگر دستور start بود یا دستور enable به همراه --now بود
if [ "$COMMAND" == "start" ] || ( [ "$COMMAND" == "enable" ] && [ "$START_NOW" = true ] ); then
    EXEC_START=$(sed -n 's/^ExecStart=\(.*\)/\1/p' "$SERVICE_FILE" | xargs)
    WORK_DIR=$(sed -n 's/^WorkingDirectory=\(.*\)/\1/p' "$SERVICE_FILE" | xargs)
    
    echo "Found ExecStart for $SERVICE_NAME: $EXEC_START" >> /var/log/fake_systemctl.log
    
    echo "[program:${SERVICE_NAME}]" > "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "command=${EXEC_START}" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    if [ -n "$WORK_DIR" ]; then
        echo "directory=${WORK_DIR}" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    fi
    echo "autostart=true" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "autorestart=true" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "stdout_logfile=/var/log/${SERVICE_NAME}.log" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "stderr_logfile=/var/log/${SERVICE_NAME}.err.log" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    
    supervisorctl reread >> /var/log/fake_systemctl.log 2>&1
    supervisorctl update >> /var/log/fake_systemctl.log 2>&1
    supervisorctl start "${SERVICE_NAME}" >> /var/log/fake_systemctl.log 2>&1
    exit 0

elif [ "$COMMAND" == "stop" ] || ( [ "$COMMAND" == "disable" ] && [ "$START_NOW" = true ] ); then
    supervisorctl stop "${SERVICE_NAME}"
    exit 0

elif [ "$COMMAND" == "restart" ]; then
    supervisorctl reread
    supervisorctl update
    supervisorctl restart "${SERVICE_NAME}"
    exit 0

elif [ "$COMMAND" == "is-active" ]; then
    STATE=$(supervisorctl status "${SERVICE_NAME}" 2>/dev/null | awk '{print $2}')
    if [[ "$STATE" == "RUNNING" ]]; then echo "active"; exit 0; else echo "inactive"; exit 3; fi

# اگر فقط enable یا disable خالی بود و --now نداشت (تایید الکی برای رد شدن بدون خطا)
elif [ "$COMMAND" == "enable" ] || [ "$COMMAND" == "disable" ]; then
    exit 0
fi

exit 0
