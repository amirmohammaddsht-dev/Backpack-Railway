FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب Nginx و gettext (برای envsubst)
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget libc6-compat socat gawk nginx gettext

RUN echo -e '#!/bin/bash\nexec "$@"' > /usr/bin/sudo && chmod +x /usr/bin/sudo

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y nginx wget curl jq tar && apt-get clean

# ساخت تمام پوشه‌هایی که install.sh به صورت پیش‌فرض می‌سازد
RUN mkdir -p /etc/backpack /root/BackPack/backups /opt/defaults

# دانلود باینری، اعتبارسنجی امنیتی SHA256 و نصب هسته مشابه رفتار رسمی بک‌پک
RUN wget -O /tmp/backpack_linux_amd64.tar.gz https://github.com/AminMGMT/BackPack/releases/latest/download/backpack_linux_amd64.tar.gz && \
    wget -O /tmp/SHA256SUMS https://github.com/AminMGMT/BackPack/releases/latest/download/SHA256SUMS && \
    cd /tmp && grep "backpack_linux_amd64.tar.gz" SHA256SUMS | sha256sum -c - && \
    tar -xzf backpack_linux_amd64.tar.gz && \
    install -m 0755 backpack /usr/local/bin/backpack && \
    echo /root/BackPack > /etc/backpack/install_path && \
    rm -f /tmp/backpack* /tmp/SHA256SUMS

ENV PORT=8080
CMD ["/start.sh"]
# کپی کردن قالب Nginx
COPY nginx.conf.template /etc/nginx/nginx.conf.template

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]