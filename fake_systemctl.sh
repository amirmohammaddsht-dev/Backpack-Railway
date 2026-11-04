#!/bin/bash
COMMAND=$1
SERVICE=$2

# لاگ کردن تمام درخواست‌های بک‌پک برای عیب‌یابی
echo "[$(date)] systemctl $COMMAND $SERVICE" >> /var/log/fake_systemctl.log

if [ -z "$SERVICE" ] || [ "$COMMAND" == "enable" ] || [ "$COMMAND" == "daemon-reload" ]; then exit 0; fi

SERVICE_NAME=$(basename "$SERVICE" .service)
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ "$COMMAND" == "start" ]]; then
    EXEC_START=$(sed -n 's/^ExecStart=\(.*\)/\1/p' "$SERVICE_FILE" | xargs)
    WORK_DIR=$(sed -n 's/^WorkingDirectory=\(.*\)/\1/p' "$SERVICE_FILE" | xargs)
    
    echo "Found ExecStart: $EXEC_START" >> /var/log/fake_systemctl.log
    
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

elif [[ "$COMMAND" == "stop" ]]; then
    supervisorctl stop "${SERVICE_NAME}"
    exit 0

elif [[ "$COMMAND" == "restart" ]]; then
    supervisorctl reread
    supervisorctl update
    supervisorctl restart "${SERVICE_NAME}"
    exit 0

elif [[ "$COMMAND" == "is-active" ]]; then
    STATE=$(supervisorctl status "${SERVICE_NAME}" | awk '{print $2}')
    if [[ "$STATE" == "RUNNING" ]]; then echo "active"; exit 0; else echo "inactive"; exit 3; fi
fi

exit 0
