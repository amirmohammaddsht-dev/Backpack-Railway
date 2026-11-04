FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ۱. نصب پکیج‌های لینوکسی مورد نیاز
RUN apt-get update && apt-get install -y curl wget git python3 nano sudo iptables iproute2 net-tools tzdata cron unzip jq sqlite3 systemd systemd-sysv

# ۲. نصب شبیه‌ساز systemd به عنوان جایگزین کرنل برای PaaS
RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /bin/systemctl && \
    chmod +x /bin/systemctl

# ۳. نصب پنل ۳x-ui و قفل کردن پورت روی ۲۰۵۳ (با یوزر و رمز admin)
RUN curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh -o x-ui-install.sh && \
    sed -i 's/last_version=.*/last_version="v3.11.0"/g' x-ui-install.sh && \
    chmod +x x-ui-install.sh && \
    yes "" | bash x-ui-install.sh || true && \
    /usr/local/x-ui/x-ui setting -username admin -password admin -port 2053 && \
    /bin/systemctl enable x-ui

# ۴. دانلود و راه‌اندازی سورس کامل BackPack
RUN git clone https://github.com/AminMGMT/BackPack.git /opt/BackPack && \
    chmod +x /opt/BackPack/install.sh && \
    echo '#!/bin/bash' > /usr/bin/backpack && \
    echo 'cd /opt/BackPack && bash install.sh "$@"' >> /usr/bin/backpack && \
    chmod +x /usr/bin/backpack

# ۵. معرفی پورت‌های پنل و تانل به فایروال کلود
EXPOSE 2053
EXPOSE 8080

# ۶. استارت کردن شبیه‌ساز سیستم‌عامل به عنوان پروسه اصلی (حل مشکل توقف پنل)
CMD ["/bin/systemctl"]
