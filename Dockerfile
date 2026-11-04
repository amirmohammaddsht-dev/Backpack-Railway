FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ۱. نصب پیش‌نیازها
RUN apt-get update && apt-get install -y curl wget git python3 nano sudo iptables iproute2 net-tools tzdata cron unzip jq

# ۲. نصب شبیه‌ساز systemd برای اجرای بی‌نقص بک‌پک و ثنایی
RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /bin/systemctl && \
    chmod +x /bin/systemctl

# ۳. نصب ثنایی (حل مشکل ارور 404 و لیمیت گیت‌هاب)
RUN curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh -o x-ui-install.sh && \
    # پیدا کردن آخرین نسخه بدون درگیر شدن با محدودیت API
    LATEST=$(curl -sI https://github.com/mhsanaei/3x-ui/releases/latest | grep -i "^location:" | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "v2.4.4") && \
    # تزریق نسخه پیدا شده به اسکریپت ثنایی
    sed -i "s/last_version=.*/last_version=\"$LATEST\"/" x-ui-install.sh && \
    chmod +x x-ui-install.sh && \
    bash x-ui-install.sh admin admin 2053

# ۴. نصب کامل ریپازیتوری BackPack
RUN git clone https://github.com/AminMGMT/BackPack.git /etc/BackPack && \
    cd /etc/BackPack && \
    chmod +x install.sh && \
    yes "" | ./install.sh || true && \
    ln -sf /etc/BackPack/backpack.sh /usr/bin/backpack && \
    chmod +x /usr/bin/backpack

# ۵. اسکریپت راه‌انداز سیستم
RUN echo '#!/bin/bash' > /start.sh && \
    echo '/bin/systemctl start x-ui' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]
