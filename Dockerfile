FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran

# نصب پیش‌نیازها و ابزار ویرایش دیتابیس
RUN apt-get update && apt-get install -y \
    wget curl git nano iproute2 net-tools iptables tzdata ca-certificates unzip sqlite3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local

# دانلود و نصب پنل 3x-ui
RUN wget -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar zxvf x-ui-linux-amd64.tar.gz \
    && rm x-ui-linux-amd64.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

# دانلود و قرار دادن دقیق هسته Xray در مسیر مورد نیاز پنل
RUN mkdir -p /usr/local/x-ui/bin \
    && wget -O xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip xray.zip -d xray_temp \
    && mv xray_temp/xray /usr/local/x-ui/bin/xray-linux-amd64 \
    && chmod +x /usr/local/x-ui/bin/xray-linux-amd64 \
    && rm -rf xray.zip xray_temp

# دریافت سورس C-Tunnel
RUN git clone https://github.com/CIAUB/C-Tunnel.git /app/c-tunnel

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
