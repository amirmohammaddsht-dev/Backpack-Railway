FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran

# نصب پیش‌نیازهای لینوکس
RUN apt-get update && apt-get install -y \
    wget curl git nano iproute2 net-tools iptables tzdata ca-certificates unzip sqlite3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# نصب Go 1.22
RUN wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz \
    && rm go1.22.2.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /usr/local

# نصب پنل 3x-ui و هسته Xray
RUN wget -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar zxvf x-ui-linux-amd64.tar.gz \
    && rm x-ui-linux-amd64.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

RUN mkdir -p /usr/local/x-ui/bin \
    && wget -O xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip xray.zip -d xray_temp \
    && mv xray_temp/xray /usr/local/x-ui/bin/xray-linux-amd64 \
    && chmod +x /usr/local/x-ui/bin/xray-linux-amd64 \
    && rm -rf xray.zip xray_temp

# نصب و کامپایل جهانی C-Tunnel
WORKDIR /app
RUN git clone https://github.com/CIAUB/C-Tunnel.git c-tunnel
WORKDIR /app/c-tunnel
RUN go build -o /usr/local/bin/ctunnel ./cmd/ctunnel/
RUN go build -o /usr/local/bin/ctunnel-engine ./cmd/ctunnel-engine/
RUN mkdir -p /usr/local/lib/ctunnel && touch /usr/local/lib/ctunnel/ctunnel-kernel && chmod +x /usr/local/lib/ctunnel/ctunnel-kernel

# ساخت systemctl مجازی با روش استاندارد (بدون ارور پارسر Fly.io)
RUN echo '#!/bin/sh' > /usr/bin/systemctl && \
    echo 'echo "Fake systemctl called: $@"' >> /usr/bin/systemctl && \
    echo 'exit 0' >> /usr/bin/systemctl && \
    chmod +x /usr/bin/systemctl

# انتقال و اجرای اسکریپت راه‌انداز
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
