FROM ghcr.io/mhsanaei/3x-ui:latest

# فقط ابزارهای ضروری برای اجرای پنل، تونل و سوپروایزر
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget libc6-compat gawk

# جعل sudo برای بک‌پک
RUN echo -e '#!/bin/bash\nexec "$@"' > /usr/bin/sudo && chmod +x /usr/bin/sudo

RUN mkdir -p /etc/systemd/system/ /var/log/ /etc/supervisor/custom.d/
COPY fake_systemctl.sh /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

COPY fake_journalctl.sh /usr/bin/journalctl
RUN chmod +x /usr/bin/journalctl

RUN git clone https://github.com/AminMGMT/BackPack.git /opt/backpack
WORKDIR /opt/backpack
RUN chmod +x *.sh || true
RUN echo -e '#!/bin/bash\ncd /opt/backpack\nbash ./*.sh "$@"' > /usr/local/bin/backpack && chmod +x /usr/local/bin/backpack

RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# نصب Nginx
RUN apk update && apk add --no-cache nginx
# کپی تنظیمات Nginx و اسکریپت راه‌انداز
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY start-nginx.sh /start-nginx.sh
RUN chmod +x /start-nginx.sh

# [ادامه دستورات قبلی شما مانند کپی فایل‌های fake_systemctl و supervisord]
# اطمینان حاصل کنید که این خط در انتهای فایل وجود دارد:
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# باز کردن پورت‌ها برای اطلاع داکر و پلتفرم Railway (پنل، بک‌پک، وب‌سوکت Xray)
EXPOSE 2053 7777

ENTRYPOINT ["/entrypoint.sh"]