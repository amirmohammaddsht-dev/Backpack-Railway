#!/bin/bash
COMMAND=$1
SERVICE=$2

# اگر نام سرویس خالی بود یا دستور enable/daemon-reload بود فقط تایید کن
if [ -z "$SERVICE" ] || [ "$COMMAND" == "enable" ] || [ "$COMMAND" == "daemon-reload" ]; then exit 0; fi

SERVICE_NAME=$(basename "$SERVICE" .service)

if [[ "$COMMAND" == "start" ]]; then
    # خواندن دستور اجرای اصلی از فایل بک‌پک
    EXEC_START=$(awk -F= '/^ExecStart=/ {print $2}' "/etc/systemd/system/${SERVICE_NAME}.service" | sed 's/^[ \t]*//')
    
    # ساخت کانفیگ داکر/سوپروایزر به صورت داینامیک
    echo "[program:${SERVICE_NAME}]" > "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "command=${EXEC_START}" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "autostart=true" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "autorestart=true" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "stdout_logfile=/var/log/${SERVICE_NAME}.log" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    echo "stderr_logfile=/var/log/${SERVICE_NAME}.err.log" >> "/etc/supervisor/conf.d/${SERVICE_NAME}.conf"
    
    # اعمال تغییرات و اجرای تونل
    supervisorctl update
    supervisorctl start "${SERVICE_NAME}"
    exit 0

elif [[ "$COMMAND" == "stop" ]]; then
    supervisorctl stop "${SERVICE_NAME}"
    exit 0

elif [[ "$COMMAND" == "restart" ]]; then
    supervisorctl restart "${SERVICE_NAME}"
    exit 0

elif [[ "$COMMAND" == "is-active" ]]; then
    # بررسی روشن بودن تونل
    STATE=$(supervisorctl status "${SERVICE_NAME}" | awk '{print $2}')
    if [[ "$STATE" == "RUNNING" ]]; then echo "active"; exit 0; else echo "inactive"; exit 3; fi
fi

exit 0
