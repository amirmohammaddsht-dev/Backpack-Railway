FROM ghcr.io/mhsanaei/3x-ui:latest

# اضافه شدن socat برای هدایت پورت و ابزارهای مورد نیاز
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget libc6-compat socat

# جعل (Mock) کردن systemd برای جلوگیری از کرش نصب بک‌پک
RUN mkdir -p /etc/systemd/system/ /run/systemd/system/ && \
    echo -e '#!/bin/bash\nexit 0' > /usr/bin/systemctl && \
    chmod +x /usr/bin/systemctl

# دریافت سورس بک‌پک
RUN git clone https://github.com/AminMGMT/BackPack.git /opt/backpack
WORKDIR /opt/backpack
RUN chmod +x *.sh || true

# ساخت یک دستور سراسری برای اجرای بک‌پک
RUN echo -e '#!/bin/bash\ncd /opt/backpack\nbash ./*.sh "$@"' > /usr/local/bin/backpack && chmod +x /usr/local/bin/backpack

# تنظیمات سوپروایزر
RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
