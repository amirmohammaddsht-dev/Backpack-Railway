FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran

RUN apt-get update && apt-get install -y \
    wget curl git nano iproute2 net-tools iptables tzdata ca-certificates unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# نصب پنل سنایی
WORKDIR /usr/local
RUN wget -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar zxvf x-ui-linux-amd64.tar.gz \
    && rm x-ui-linux-amd64.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

# دانلود و نصب هسته Xray
RUN mkdir -p /usr/local/x-ui/bin \
    && wget -O xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip xray.zip -d xray_extracted \
    && mv xray_extracted/xray /usr/local/x-ui/bin/xray-linux-amd64 \
    && chmod +x /usr/local/x-ui/bin/xray-linux-amd64 \
    && rm -rf xray.zip xray_extracted

# دریافت سورس C-Tunnel
RUN git clone https://github.com/CIAUB/C-Tunnel.git /app/c-tunnel

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
