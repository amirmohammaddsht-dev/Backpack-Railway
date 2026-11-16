FROM ghcr.io/mhsanaei/3x-ui:latest

# فقط ابزارهای ضروری برای اجرای پنل، تونل و سوپروایزر
RUN apk update && apk add --no-cache git curl sqlite supervisor bash jq wget libc6-compat gawk

# جعل sudo برای بک‌پک
RUN echo -e '#!/bin/bash\nexec "$@"' > /usr/bin/sudo && chmod +x /usr/bin/sudo

RUN mkdir -p /etc/systemd/system/ /var/log/ /etc/supervisor/custom.d/
COPY fake_systemctl.sh /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

COPY fake_journalctl.sh /usr/bin/journalctl
RUN chmod +x /usr/bin/journalctl

# BackPack: official static release binary, verified against the published SHA256SUMS.
# It must live at /usr/local/bin/backpack, because the tunnel unit it writes runs
# "/usr/local/bin/backpack -c /etc/backpack/<name>.toml".
# Pin a version with: --build-arg BACKPACK_VERSION=v1.8.5  (default: latest)
ARG BACKPACK_VERSION=latest
RUN set -eux; \
    case "$(uname -m)" in \
      x86_64|amd64)  ARCH=amd64 ;; \
      aarch64|arm64) ARCH=arm64 ;; \
      *) echo "unsupported architecture: $(uname -m)"; exit 1 ;; \
    esac; \
    if [ "$BACKPACK_VERSION" = "latest" ]; then \
      BASE="https://github.com/AminMGMT/BackPack/releases/latest/download"; \
    else \
      BASE="https://github.com/AminMGMT/BackPack/releases/download/${BACKPACK_VERSION}"; \
    fi; \
    ASSET="backpack_linux_${ARCH}.tar.gz"; \
    cd /tmp; \
    curl -fsSL -o "$ASSET" "$BASE/$ASSET"; \
    curl -fsSL -o SHA256SUMS "$BASE/SHA256SUMS"; \
    grep -E "[[:space:]]\*?${ASSET}\$" SHA256SUMS | sha256sum -c -; \
    tar -xzf "$ASSET" backpack; \
    install -m 0755 backpack /usr/local/bin/backpack; \
    rm -f "$ASSET" SHA256SUMS backpack; \
    mkdir -p /etc/backpack

RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# fake_systemctl.sh calls a bare `supervisorctl`, which only finds its socket through a
# config in one of its default locations - point /etc/supervisord.conf at ours.
RUN ln -sf /etc/supervisor/conf.d/supervisord.conf /etc/supervisord.conf

COPY apply-link.sh /usr/local/bin/apply-link.sh
RUN chmod +x /usr/local/bin/apply-link.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# باز کردن پورت‌ها برای اطلاع داکر و پلتفرم Railway (پنل، بک‌پک، وب‌سوکت Xray)
EXPOSE 2053 7777

ENTRYPOINT ["/entrypoint.sh"]