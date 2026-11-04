FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب ابزارهای مورد نیاز
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget libc6-compat socat gawk

# کپی کردن اسکریپت‌های مترجم هوشمند برای اجرای بک‌پک در داکر
RUN mkdir -p /etc/systemd/system/ /var/log/
COPY fake_systemctl.sh /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

COPY fake_journalctl.sh /usr/bin/journalctl
RUN chmod +x /usr/bin/journalctl

# دریافت سورس بک‌پک
RUN git clone https://github.com/AminMGMT/BackPack.git /opt/backpack
WORKDIR /opt/backpack
RUN chmod +x *.sh || true

# ساخت یک دستور سراسری برای اجرای منوی بک‌پک
RUN echo -e '#!/bin/bash\ncd /opt/backpack\nbash ./*.sh "$@"' > /usr/local/bin/backpack && chmod +x /usr/local/bin/backpack

# تنظیمات سوپروایزر و اسکریپت اجرایی اصلی
RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
