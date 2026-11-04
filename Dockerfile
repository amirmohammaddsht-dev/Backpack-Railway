FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ۱. نصب پکیج‌های پایه‌ای
RUN apt-get update && apt-get install -y curl wget git python3 nano sudo iptables iproute2 net-tools tzdata cron unzip jq sqlite3

# ۲. نصب پنل ۳x-ui و تنظیم اجباری یوزر و پسورد admin روی پورت 2053
RUN curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh -o x-ui-install.sh && \
    sed -i 's/last_version=.*/last_version="v3.11.0"/g' x-ui-install.sh && \
    chmod +x x-ui-install.sh && \
    yes "" | bash x-ui-install.sh || true && \
    /usr/local/x-ui/x-ui setting -username admin -password admin -port 2053

# ۳. نصب کامل سورس BackPack
RUN git clone https://github.com/AminMGMT/BackPack.git /opt/BackPack && \
    chmod +x /opt/BackPack/install.sh && \
    echo '#!/bin/bash' > /usr/bin/backpack && \
    echo 'cd /opt/BackPack && bash install.sh "$@"' >> /usr/bin/backpack && \
    chmod +x /usr/bin/backpack

EXPOSE 2053
EXPOSE 8080

# ۴. اسکریپت استارت ایمن بدون دستورات ری‌استارت‌کننده
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'cd /usr/local/x-ui && ./x-ui & ' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]
