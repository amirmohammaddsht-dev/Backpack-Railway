FROM ghcr.io/mhsanaei/3x-ui:latest

# استفاده از apk به جای apt-get برای نصب ابزارها روی ایمیج آلپاین
RUN apk update && apk add --no-cache curl gzip && \
    curl -s https://api.github.com/repos/jpillora/chisel/releases/latest \
    | grep browser_download_url | grep linux_amd64.gz \
    | cut -d '"' -f 4 | xargs curl -L -o chisel.gz && \
    gzip -d chisel.gz && \
    mv chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

ENV CHISEL_AUTH="admin:MySecretPassword"

# اسکریپت راه‌انداز
RUN echo '#!/bin/sh' > /start-both.sh && \
    echo '/usr/local/bin/chisel server --port 8080 --auth "${CHISEL_AUTH}" --socks5 & ' >> /start-both.sh && \
    echo 'cd /usr/local/x-ui && ./x-ui' >> /start-both.sh && \
    chmod +x /start-both.sh

CMD ["/start-both.sh"]
