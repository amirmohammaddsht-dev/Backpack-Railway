FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب ابزارها با استفاده از apk (پکیج منیجر Alpine)
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget

# دانلود پروژه BackPack
RUN git clone https://github.com/AminMGMT/BackPack.git /opt/backpack
WORKDIR /opt/backpack
RUN chmod +x *.sh || true

# ساخت مسیر کانفیگ سوپروایزر (در آلپاین ممکن است پوشه پیش‌فرض وجود نداشته باشد)
RUN mkdir -p /etc/supervisor/conf.d/

# کپی کردن فایل‌های کانفیگ به داخل کانتینر
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
