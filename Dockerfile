FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ۱. نصب پیش‌نیازهای لینوکسی برای اجرای پنل و بک‌پک
RUN apt-get update && apt-get install -y curl wget git python3 nano sudo iptables iproute2 net-tools tzdata cron unzip jq

# ۲. نصب شبیه‌ساز systemd برای محیط‌های PaaS (Fly.io / Railway)
RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /bin/systemctl && \
    chmod +x /bin/systemctl

# ۳. نصب کاملاً خودکار پنل ثنایی (یوزر: admin | رمز: admin | پورت: 2053)
RUN curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh -o x-ui-install.sh && \
    chmod +x x-ui-install.sh && \
    bash x-ui-install.sh admin admin 2053

# ۴. دانلود و نصب کاملاً خودکار پنل BackPack
RUN git clone https://github.com/AminMGMT/BackPack.git /etc/BackPack && \
    cd /etc/BackPack && \
    chmod +x install.sh && \
    # استفاده از yes برای رد کردن خودکار سوالات فرم نصب
    yes "" | ./install.sh || true && \
    # اطمینان از اینکه دستور backpack در کل سرور شناسایی می‌شود
    ln -sf /etc/BackPack/backpack.sh /usr/bin/backpack && \
    chmod +x /usr/bin/backpack

# ۵. اسکریپت راه‌انداز اصلی کانتینر
RUN echo '#!/bin/bash' > /start.sh && \
    echo '/bin/systemctl start x-ui' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]
