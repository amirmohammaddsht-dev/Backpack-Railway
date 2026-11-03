FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran

# نصب پیش‌نیازهای لینوکس
RUN apt-get update && apt-get install -y \
    wget curl git nano iproute2 net-tools iptables tzdata ca-certificates unzip sqlite3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# نصب Go نسخه 1.22 برای سازگاری کامل با C-Tunnel
RUN wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz \
    && rm go1.22.2.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /usr/local

# دانلود و نصب پنل 3x-ui
RUN wget -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar zxvf x-ui-linux-amd64.tar.gz \
    && rm x-ui-linux-amd64.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

# دانلود و استخراج دقیق هسته Xray در مسیر مورد نیاز پنل
RUN mkdir -p /usr/local/x-ui/bin \
    && wget -O xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip xray.zip -d xray_temp \
    && mv xray_temp/xray /usr/local/x-ui/bin/xray-linux-amd64 \
    && chmod +x /usr/local/x-ui/bin/xray-linux-amd64 \
    && rm -rf xray.zip xray_temp

# دریافت سورس C-Tunnel و کامپایل همزمان رابط کاربری و هسته پردازشی
WORKDIR /app
RUN git clone https://github.com/CIAUB/C-Tunnel.git c-tunnel
WORKDIR /app/c-tunnel
RUN go build -o c-tunnel ./cmd/ctunnel/
RUN go build -o ctunnel-engine ./cmd/ctunnel-engine/
RUN cp ctunnel-engine /usr/bin/

# کپی اسکریپت راه‌انداز هوشمند
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
