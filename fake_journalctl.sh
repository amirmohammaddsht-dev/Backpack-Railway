#!/bin/bash
FOLLOW=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u) SERVICE="$2"; shift ;;
        -f) FOLLOW=true ;;
    esac
    shift
done

if [ -n "$SERVICE" ]; then
    SERVICE_NAME=$(basename "$SERVICE" .service)
    # نمایش لاگ‌های سوپروایزر به بک‌پک
    if [ "$FOLLOW" = true ]; then
        tail -f "/var/log/${SERVICE_NAME}.log" "/var/log/${SERVICE_NAME}.err.log" 2>/dev/null
    else
        cat "/var/log/${SERVICE_NAME}.log" "/var/log/${SERVICE_NAME}.err.log" 2>/dev/null
    fi
fi
exit 0
