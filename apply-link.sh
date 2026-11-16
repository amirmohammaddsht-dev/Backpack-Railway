#!/bin/bash
# Runs once under supervisord (program: tunnel-setup).
# Builds the tunnel described by the BackPack setup link in $TUNNEL_LINK.
#
#   TUNNEL_LINK  (required)  the backpack://... link printed by the Iran server
#   TUNNEL_NAME  (optional)  replaces the tunnel name suggested by the link
#   TUNNEL_HOST  (optional)  Iran server address, only if the link does not carry it
#
# `backpack link apply` writes the tunnel's unit file and calls `systemctl enable --now`;
# fake_systemctl.sh turns that into a supervisord program, so the tunnel runs (and is
# restarted) by supervisord like everything else in this container.

if [ -z "${TUNNEL_LINK:-}" ]; then
    echo "[tunnel-setup] TUNNEL_LINK is not set - no tunnel will be created."
    exit 0
fi

ARGS=()
[ -n "${TUNNEL_NAME:-}" ] && ARGS+=(--name "$TUNNEL_NAME")
[ -n "${TUNNEL_HOST:-}" ] && ARGS+=(--host "$TUNNEL_HOST")

echo "[tunnel-setup] Applying the setup link from TUNNEL_LINK..."
backpack link apply ${ARGS[@]+"${ARGS[@]}"} "$TUNNEL_LINK"
rc=$?

case "$rc" in
    0) echo "[tunnel-setup] Tunnel is up and connected." ;;
    4) echo "[tunnel-setup] Tunnel is running but has not connected yet; supervisord keeps it running and it keeps retrying on its own."
       rc=0 ;;
    *) echo "[tunnel-setup] link apply failed (exit $rc). Check that TUNNEL_LINK is the complete link from the Iran server." ;;
esac
exit "$rc"