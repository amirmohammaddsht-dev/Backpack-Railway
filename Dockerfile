FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب ابزارهای پیش‌نیاز
RUN apt-get update && apt-get install -y git curl sqlite3 supervisor bash jq wget && rm -rf /var/lib/apt/lists/*

# دانلود پروژه BackPack
RUN git clone https://github.com/AminMGMT/BackPack.git /opt/backpack
WORKDIR /opt/backpack
RUN chmod +x *.sh || true

# کپی کردن فایل‌های کانفیگ به داخل کانتینر
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# مسیر دیتابیس پنل ثنایی برای اتصال به Volume
VOLUME [ "/etc/x-ui" ]

ENTRYPOINT ["/entrypoint.sh"]
