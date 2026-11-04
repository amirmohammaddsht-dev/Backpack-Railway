FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y curl wget git python3 nano sudo iptables iproute2 net-tools tzdata cron unzip jq sqlite3 systemd systemd-sysv

RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /bin/systemctl && \
    chmod +x /bin/systemctl

RUN curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh -o x-ui-install.sh && \
    sed -i 's/last_version=.*/last_version="v3.11.0"/g' x-ui-install.sh && \
    chmod +x x-ui-install.sh && \
    yes "" | bash x-ui-install.sh || true && \
    /usr/local/x-ui/x-ui setting -username admin -password admin -port 2053 && \
    /bin/systemctl enable x-ui

RUN git clone https://github.com/AminMGMT/BackPack.git /opt/BackPack && \
    chmod +x /opt/BackPack/install.sh && \
    echo '#!/bin/bash' > /usr/bin/backpack && \
    echo 'cd /opt/BackPack && bash install.sh "$@"' >> /usr/bin/backpack && \
    chmod +x /usr/bin/backpack

EXPOSE 2053
EXPOSE 8080

# استفاده از اسکریپت واسط برای روشن نگه داشتن ابدی کانتینر در Fly.io
RUN echo '#!/bin/bash' > /start.sh && \
    echo '/bin/systemctl start x-ui' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]
