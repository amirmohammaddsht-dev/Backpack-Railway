#!/bin/bash
FOLLOW=false
LINES=50

# استخراج آرگومان‌های ارسالی از سمت بک‌پک
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u) SERVICE="$2"; shift ;;
        -f) FOLLOW=true ;;
        -n) LINES="$2"; shift ;;
    esac
    shift
done

if [ -n "$SERVICE" ]; then
    SERVICE_NAME=$(basename "$SERVICE" .service)
    LOG_FILE="/var/log/${SERVICE_NAME}.log"
    ERR_FILE="/var/log/${SERVICE_NAME}.err.log"
    
    # تابع قالب‌بندی لاگ با رنگ‌های دقیق BackPack
    format_log() {
        # awk برای اضافه کردن رنگ‌ها بر اساس نوع پیام
        awk '
        {
            # رنگ‌های استاندارد ANSI
            RESET="\033[0m"
            INFO="\033[1;34m"    # Blue
            WARN="\033[1;33m"    # Yellow
            ERR="\033[1;31m"     # Red
            SUCCESS="\033[1;32m" # Green
            
            line = $0
            if (match(line, /\[INFO\]/)) {
                sub(/\[INFO\]/, INFO "[INFO]" RESET, line)
            } else if (match(line, /\[WARNING\]/)) {
                sub(/\[WARNING\]/, WARN "[WARNING]" RESET, line)
            } else if (match(line, /\[ERROR\]|failed|FATAL/)) {
                sub(/\[ERROR\]/, ERR "[ERROR]" RESET, line)
                line = ERR line RESET
            } else if (match(line, /successfully|up/)) {
                line = SUCCESS line RESET
            }
            print line
        }'
    }

    # بررسی وجود فایل لاگ
    if [ ! -f "$LOG_FILE" ] && [ ! -f "$ERR_FILE" ]; then
        echo -e "\033[1;31m[ERROR]\033[0m No logs found for service: ${SERVICE_NAME}"
        exit 1
    fi

    # اجرای دستور tail با یا بدون سوییچ follow (-f)
    if [ "$FOLLOW" = true ]; then
        # ادغام لاگ‌های معمولی و ارور و ارسال به تابع قالب‌بندی
        tail -n "$LINES" -F "$LOG_FILE" "$ERR_FILE" 2>/dev/null | grep -v "==>" | format_log
    else
        tail -n "$LINES" "$LOG_FILE" "$ERR_FILE" 2>/dev/null | grep -v "==>" | format_log
    fi
fi
exit 0