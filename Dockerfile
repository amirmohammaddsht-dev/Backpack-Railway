FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب ابزارهای دانلود و هسته تانل (Chisel)
RUN apt-get update && apt-get install -y curl gzip && \
    curl -s https://api.github.com/repos/jpillora/chisel/releases/latest \
    | grep browser_download_url | grep linux_amd64.gz \
    | cut -d '"' -f 4 | xargs curl -L -o chisel.gz && \
    gzip -d chisel.gz && \
    mv chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# تنظیم رمز عبور تانل (برای امنیت حتما تغییر دهید)
ENV CHISEL_AUTH="admin:MySecretPassword"

# ساخت اسکریپت راه‌انداز همزمان
RUN echo '#!/bin/sh' > /start-both.sh && \
    echo '/usr/local/bin/chisel server --port 8080 --auth "${CHISEL_AUTH}" --socks5 & ' >> /start-both.sh && \
    echo 'cd /usr/local/x-ui && ./x-ui' >> /start-both.sh && \
    chmod +x /start-both.sh

# اجرای اسکریپت هنگام روشن شدن سرور
CMD ["/start-both.sh"]
