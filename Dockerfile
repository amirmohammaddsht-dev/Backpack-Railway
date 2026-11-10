FROM ghcr.io/mhsanaei/3x-ui:latest

# نصب Nginx و gettext (برای envsubst)
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget libc6-compat socat gawk nginx gettext

RUN echo -e '#!/bin/bash\nexec "$@"' > /usr/bin/sudo && chmod +x /usr/bin/sudo

RUN mkdir -p /etc/systemd/system/ /var/log/ /etc/supervisor/custom.d/ /run/nginx/
COPY fake_systemctl.sh /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

COPY fake_journalctl.sh /usr/bin/journalctl
RUN chmod +x /usr/bin/journalctl

RUN wget -O /tmp/backpack.tar.gz https://github.com/AminMGMT/BackPack/releases/latest/download/backpack_linux_amd64.tar.gz && \
    tar -xzf /tmp/backpack.tar.gz -C /opt/backpack/ && \
    rm /tmp/backpack.tar.gz

#COPY webui.json /etc/backpack/webui.json
#COPY nginx.conf /etc/nginx/nginx.conf
#COPY start.sh /start.sh

#RUN chmod +x /start.sh && \
    #chmod +x /opt/backpack/backpack

RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# کپی کردن قالب Nginx
COPY nginx.conf.template /etc/nginx/nginx.conf.template

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]