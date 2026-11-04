#!/bin/bash

echo "[$(date)] systemctl $*" >> /var/log/fake_systemctl.log

COMMAND=$1
shift 

START_NOW=false
if [ "$1" == "--now" ]; then
    START_NOW=true
    shift 
fi

SERVICE=$1

if [ -z "$SERVICE" ] || [ "$COMMAND" == "daemon-reload" ]; then exit 0; fi

SERVICE_NAME=$(basename "$SERVICE" .service)
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [ "$COMMAND" == "start" ] || ( [ "$COMMAND" == "enable" ] && [ "$START_NOW" = true ] ); then
    EXEC_START=$(sed -n 's/^ExecStart=\(.*\)/\1/p' "$SERVICE_FILE" | xargs)
    WORK_DIR=$(sed -n 's/^WorkingDirectory=\(.*\)/\1/p' "$SERVICE_FILE" | xargs)
    
    echo "Found ExecStart for $SERVICE_NAME: $EXEC_START" >> /var/log/fake_systemctl.log
    
    # ذخیره کانفیگ در مسیر custom.d
    CONF_FILE="/etc/supervisor/custom.d/${SERVICE_NAME}.conf"
    
    echo "[program:${SERVICE_NAME}]" > "$CONF_FILE"
    echo "command=${EXEC_START}" >> "$CONF_FILE"
    if [ -n "$WORK_DIR" ]; then
        echo "directory=${WORK_DIR}" >> "$CONF_FILE"
    fi
    echo "autostart=true" >> "$CONF_FILE"
    echo "autorestart=true" >> "$CONF_FILE"
    echo "stdout_logfile=/var/log/${SERVICE_NAME}.log" >> "$CONF_FILE"
    echo "stderr_logfile=/var/log/${SERVICE_NAME}.err.log" >> "$CONF_FILE"
    
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

elif [ "$COMMAND" == "enable" ] || [ "$COMMAND" == "disable" ]; then
    exit 0
fi

exit 0
