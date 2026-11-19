FROM ghcr.io/mhsanaei/3x-ui:latest

# Only what runs here: supervisor runs every process, gawk is what the log colouring in
# fake_journalctl.sh is written for. bash and curl are already in the base image.
# Everything else this image used to install (git, jq, wget, sqlite, libc6-compat) is gone:
# BackPack is now a static release binary, not a cloned repository.
RUN apk add --no-cache supervisor bash curl gawk \
    && mkdir -p /etc/supervisor/conf.d /etc/supervisor/custom.d /etc/systemd/system /etc/backpack /var/log \
    # BackPack calls sudo; there is nobody to elevate to in a container
    && printf '#!/bin/bash\nexec "$@"\n' > /usr/bin/sudo && chmod +x /usr/bin/sudo \
    # Unit files for the web panel and the monitor. They run as programs of supervisord.conf;
    # these files exist because BackPack treats a missing unit as "service not installed".
    && for s in webui monitor; do \
         printf '[Service]\nExecStart=/usr/local/bin/backpack --%s\nRestart=always\n' "$s" \
           > "/etc/systemd/system/backpack-$s.service"; \
       done

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
    rm -f "$ASSET" SHA256SUMS backpack

COPY fake_systemctl.sh /usr/bin/systemctl
COPY fake_journalctl.sh /usr/bin/journalctl
COPY apply-link.sh /usr/local/bin/apply-link.sh
COPY panel-config.sh /usr/local/bin/panel-config.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

# fake_systemctl.sh calls a bare `supervisorctl`, which only finds its socket through a
# config in one of its default locations - point /etc/supervisord.conf at ours.
RUN chmod +x /usr/bin/systemctl /usr/bin/journalctl /usr/local/bin/apply-link.sh \
             /usr/local/bin/panel-config.sh /entrypoint.sh \
    && ln -sf /etc/supervisor/conf.d/supervisord.conf /etc/supervisord.conf

# Ports for the platform: 2053 = 3x-ui panel, 7777 = BackPack web panel
EXPOSE 2053 7777

ENTRYPOINT ["/entrypoint.sh"]