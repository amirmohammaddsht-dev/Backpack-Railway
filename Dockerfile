FROM ubuntu:22.04

# جلوگیری از درخواست‌های تعاملی هنگام نصب پکیج‌ها
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran

# نصب پیش‌نیازهای اولیه
RUN apt-get update && apt-get install -y \
    wget curl git unzip jq tzdata ca-certificates \
    python3 python3-pip golang \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# نصب پنل 3x-ui (بر اساس MHSanaei)
RUN mkdir -p /usr/local/x-ui
RUN wget -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar zxvf x-ui-linux-amd64.tar.gz \
    && mv x-ui/ /usr/local/ \
    && rm x-ui-linux-amd64.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

# دریافت پروژه C-Tunnel
RUN git clone https://github.com/CIAUB/C-Tunnel.git /app/c-tunnel
# در صورت نیاز به نصب پیش‌نیازهای پایتون برای C-Tunnel:
# RUN pip3 install -r /app/c-tunnel/requirements.txt

# کپی کردن اسکریپت راه‌انداز همزمان
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# باز کردن پورت‌های پیش‌فرض پنل و تانل (Railway پورت اختصاصی خود را روی متغیر PORT تنظیم می‌کند)
EXPOSE 2053 8080 8443

CMD ["/app/start.sh"]