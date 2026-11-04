FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب ابزارهای مورد نیاز + پکیج libc6-compat جهت سازگاری آلپاین برای اجرای برنامه‌های Go
RUN apk update && apk add --no-cache curl sqlite supervisor bash jq wget tar libc6-compat

# دانلود مستقیم آخرین نسخه کامپایل‌شده BackPack از گیت‌هاب و استخراج در مسیر اجرایی
RUN LATEST_URL=$(curl -s https://api.github.com/repos/AminMGMT/BackPack/releases/latest | grep "browser_download_url" | grep -i "linux-amd64" | head -n 1 | cut -d '"' -f 4) && \
    wget -qO /tmp/backpack.tar.gz "$LATEST_URL" && \
    tar -xzf /tmp/backpack.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/backpack && \
    rm /tmp/backpack.tar.gz

# ایجاد پوشه‌های مورد نیاز برای فایل‌های موقت
RUN mkdir -p /etc/supervisor/conf.d/ /opt/backpack/

# کپی فایل‌های کانفیگ به داخل کانتینر
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
