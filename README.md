<p align="center"><b>English</b> · <a href="README_FA.md">فارسی</a></p>

# Backpack-Railway

Run the **BackPack** tunnel and the **3x-ui** panel on **Railway** in a few clicks: **fork** this project, deploy your fork on Railway, and put your tunnel's setup link in one variable. That's it.

> Based on BackPack by Amin Mohammadi (AminMGMT)
> https://github.com/AminMGMT/BackPack

This repository is **unofficial** and is not BackPack itself: at build time it only downloads the official BackPack release binary and verifies its checksum. 3x-ui comes from the official `ghcr.io/mhsanaei/3x-ui` image. See [License and credits](#license-and-credits).

## Contents

- [What does this project do?](#what-does-this-project-do)
- [Install in 5 steps](#install-in-5-steps)
- [Updating your fork](#updating-your-fork)
- [Variables](#variables)
- [Port forwarding](#port-forwarding)
- [Persistence](#persistence)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Technical details](#technical-details)
- [License and credits](#license-and-credits)

---

## What does this project do?

BackPack is a tunnel between an **Iran server** and a **foreign (kharej) server**. Here the foreign server is this Railway container. You create the tunnel on the Iran server, copy its **Setup Link** (`backpack://…`), and hand it to Railway. The container then connects to Iran by itself and keeps the tunnel up. Because the container is the one that opens the connection, Railway does not have to expose any port for the tunnel.

Four things run inside the container:

| What | Role |
|---|---|
| BackPack tunnel | Built from `TUNNEL_LINK`; delivers traffic to your 3x-ui inbounds |
| 3x-ui | Panel for creating inbounds (VLESS, VMess, …), port `2053` |
| BackPack web panel | Tunnel status and logs, port `7777`, served only under a secret path |
| BackPack watchdog | Brings a tunnel back up if it drops |

```text
 User ─▶ Iran server :443
               ▲
               ║  BackPack tunnel — the Railway container dials OUT to Iran
               ▼
 Railway container ─▶ 127.0.0.1:<port> ─▶ x-ui inbound
```

---

## Install in 5 steps

1. **Fork** this repository.
2. On the **Iran server**, create the tunnel and copy its **Setup Link**.
3. In **Railway**, deploy your fork.
4. Put the link and a panel password in **Variables**.
5. Create a **domain**, read the logs, and create an inbound in 3x-ui.

### 1. Fork the project

At the top of this repository on GitHub, click **Fork**, then **Create fork**. From now on you work with your own fork.

> **Never write a link, password or token into your fork's files.** A fork of a public repository is public. Every secret goes only into **Railway → Variables**.

### 2. Create the tunnel on the Iran server

If BackPack is not installed on the Iran server yet:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh)
```

Then open the menu:

```bash
sudo backpack
```

and follow this path (accept the defaults for everything else):

```text
1. Setup Iran
→ Reverse
→ Transport            start with TCP or TCP Mux
→ Iran IP Or Domain    the address Railway must connect to
→ Tunnel Port          e.g. 3002
→ Forwarded Ports      e.g. 443=127.0.0.1:2096   (see "Port forwarding")
→ Tunnel Name
→ Security Token       generated for you; press Enter
→ How Should The Tunnel Be Tuned?   Turbo
```

The final summary shows a **Setup Link** — a single `backpack://…` line. Copy it **in full**. Then open the tunnel port and each forwarded port in the Iran server's firewall:

```bash
ufw allow 3002/tcp     # the tunnel port (use /udp for UDP tunnels such as KCP)
ufw allow 443/tcp      # the port your users connect to
```

You can get the link again later from `sudo backpack` → `Manage` → `Setup Link`.

**Which transport?** TCP and TCP Mux are a good start; TCP + Stealth, WS/WSS and UDP + KCP + FEC also work on Railway. **PCK** (needs `iptables` and raw socket access) and **Direct** tunnels (Iran has to connect out to the foreign server) do not work on Railway. For help choosing, see [Choosing a transport](https://github.com/AminMGMT/BackPack/blob/main/docs/choosing-a-transport.md).

### 3. Deploy your fork on Railway

1. Sign in at [railway.com](https://railway.com) and choose **New Project → Deploy from GitHub repo**.
2. If your fork is not listed, click **Configure GitHub App** and give Railway access to it.
3. Select your fork (`<your-username>/Backpack-Railway`). Railway finds the `Dockerfile` and builds it; this takes a few minutes.

### 4. Set the variables

Open the service → **Variables** tab → **Raw Editor**, and paste these three lines (with your own values):

```env
TUNNEL_LINK=backpack://PASTE-THE-FULL-LINK-HERE
PANEL_PATH=k7Hq2mVx9TnPaw
PANEL_PASSWORD=choose-a-strong-password
```

`TUNNEL_LINK` is the full link from step 2. `PANEL_PATH` is the secret path of the BackPack panel (8–64 letters, digits, `_` or `-`) and `PANEL_PASSWORD` is its password (at least 8 characters). Click **Deploy** and the service restarts with the new values.

### 5. Create a domain and check that it works

**Settings → Networking → Generate Domain**; when it asks for the port, enter `7777`. (Every Railway service has one domain with one target port; to see the 3x-ui panel instead, change that number to `2053`.) **Keep Replicas at 1** — two containers using the same token kick each other off the tunnel.

Under **Deployments → View Logs** you should see:

```text
[panel] web panel on port 7777 under /k7Hq2mVx9TnPaw/ (anything outside that path answers 404)
[tunnel-setup] Applying the setup link from TUNNEL_LINK...
[tunnel-setup] Tunnel is up and connected.
```

If the last line is this instead, it is not an error: the tunnel was built and keeps retrying on its own (likely causes are in [Troubleshooting](#troubleshooting)):

```text
[tunnel-setup] Tunnel is running but has not connected yet; supervisord keeps it running and it keeps retrying on its own.
```

Now:

- **BackPack panel:** open `https://<your-railway-domain>/<PANEL_PATH>/` and sign in with `PANEL_PASSWORD`. (The address without the path deliberately returns `404`.)
- **3x-ui:** temporarily set the domain's Target Port to `2053` and open `https://<your-railway-domain>/`. The first time, both username and password are `admin`; **change them immediately.** Create an **inbound whose port is exactly the one you put in the Iran server's Forwarded Ports** (`2096` in the example). The tunnel delivers traffic to `127.0.0.1:2096` inside the container, and if nothing listens there the log says `nothing is listening on 127.0.0.1:2096 on THIS server`.
- **Clients:** in the user's client config, use the **Iran server's IP** and the **public port** (e.g. `443`), not the Railway address.

---

## Updating your fork

When this repository changes, open your fork on GitHub and click **Sync fork → Update branch**. By default Railway builds and deploys again on every new commit.

Each build also fetches the latest official BackPack release. To stay on one version, add `BACKPACK_VERSION=v1.8.5` to Variables (the version this project was tested with). If Railway does not pass that variable to the build, change the default of `ARG BACKPACK_VERSION` in your fork's `Dockerfile` instead.

---

## Variables

All of them are set in **Railway → Variables**.

| Variable | Required? | Default | Description |
|---|---|---|---|
| `TUNNEL_LINK` | To build the tunnel | empty | The full Setup Link `backpack://…`. If empty, no tunnel is created. **It contains the tunnel's token; keep it secret.** |
| `TUNNEL_NAME` | No | name suggested by the link | Overrides the tunnel name |
| `TUNNEL_HOST` | No | empty | Iran server address; only needed if the link does not carry it |
| `PANEL_PATH` | Recommended | random | Secret path of the BackPack panel, 8–64 characters from `A-Z a-z 0-9 _ -` |
| `PANEL_PASSWORD` | Recommended | random | BackPack panel password, 8–128 characters |
| `PANEL_PORT` | No | `7777` | Port of the BackPack panel. The domain's Target Port must match |
| `BACKPACK_VERSION` | No | `latest` | BackPack version used at build time, e.g. `v1.8.5` |

- An invalid `PANEL_*` value is ignored and the reason is printed in the log.
- If you leave `PANEL_PATH` or `PANEL_PASSWORD` unset, a **new value is generated on every deploy** and printed once in the log (between two `=====` lines).
- Every deploy starts with a fresh container filesystem and rebuilds the tunnel from `TUNNEL_LINK`. If you change something on the Iran server (ports, transport), get a new link from `Manage → Setup Link`, put it in `TUNNEL_LINK` and deploy again.

---

## Port forwarding

On the Iran server, **Forwarded Ports** decides which public port goes to which port **inside the container**:

| Entry | Meaning |
|---|---|
| `443=127.0.0.1:2096` | Users connect to Iran:`443`; the tunnel delivers to `127.0.0.1:2096` in the container |
| `443=127.0.0.1:2096, 8443=127.0.0.1:2097` | Several inbounds over one tunnel |
| `443=127.0.0.1:2096\|127.0.0.1:2097` | Two backends, balanced and health-checked |
| `10000-10009` | A range; each port to the same port |

> **A bare `443` does not mean "any port".** It means something must really listen on `127.0.0.1:443` inside the container. If your inbound is on `2096`, write `443=127.0.0.1:2096`.

- An inbound's port must not be `2053` (3x-ui) or `7777` (BackPack panel).
- If an inbound needs **UDP**: on the Iran server turn on `Manage → Edit → Forward UDP` and run `ufw allow <port>/udp`.
- For the **real client IP**: first turn on **Accept Proxy Protocol** in the inbound, then `Manage → Edit → Real client IP` on the Iran server. The reverse order breaks every connection.
- Do not tunnel the admin panel port (2053).

Full reference: [Port mappings](https://github.com/AminMGMT/BackPack/blob/main/docs/port-mappings.md) and [Behind a panel](https://github.com/AminMGMT/BackPack/blob/main/tutorial/behind-a-panel.md).

---

## Persistence

The Railway container's filesystem is rebuilt on every deploy:

| What | After a deploy |
|---|---|
| Tunnel, BackPack panel path and password | Still there; rebuilt from `TUNNEL_LINK` and `PANEL_*` |
| 3x-ui database (inbounds, users, admin password) | **Wiped**, unless you add a Volume |
| Settings made inside the BackPack panel (2FA, Telegram) | Wiped |

To keep your inbounds: right-click the project canvas in Railway → **Volume** (or press `Ctrl+K` and search for Volume), attach it to the service, and set the **Mount Path** to `/etc/x-ui`. Only that path is recommended; a Volume on `/etc/backpack` has not been tested.

---

## Security

- **Change the 3x-ui password right away** (first boot is `admin` / `admin`). The Railway domain is public and gets scanned. You can also change the panel's Web Base Path in 3x-ui's settings.
- **Keep `TUNNEL_LINK` only in Railway Variables** — not in your fork, a chat, an issue or a log. Anyone who has it can connect to your Iran server in your place. If it leaks, change the token on the Iran server and get a new link.
- The BackPack panel **lives under a secret path and everything outside it returns `404`.** Pick `PANEL_PATH` as randomly and as long as a password. Under **Settings → Security** you can also turn on two-factor sign-in.
- After 5 wrong passwords, sign-in is blocked for 10 minutes. Behind Railway's proxy all visitors share one IP address, so a few failed attempts can lock everyone out for a while.
- Do **not** turn on the **HTTPS** option in the BackPack panel's settings; the panel serves plain HTTP and Railway provides the TLS.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| The Railway address returns `404` without a path | Normal. Open `https://<domain>/<PANEL_PATH>/` |
| `502` or "Application failed to respond" | Set the domain's Target Port to `7777` (BackPack panel) or `2053` (3x-ui); keep the BackPack panel's HTTPS off; check the logs |
| The 3x-ui login page shows instead of the BackPack panel | Target Port is `2053`; set it to `7777` |
| I don't know the panel path or password | Set `PANEL_PATH` and `PANEL_PASSWORD` in Variables and deploy again |
| "too many failed attempts" | Sign-in lockout; wait 10 minutes |
| `PANEL_PATH ignored` or `PANEL_PASSWORD ignored` | The value is invalid; fix its length and characters as in [Variables](#variables) |
| `TUNNEL_LINK is not set` | The variable is empty |
| `link apply failed (exit N)` | The link is incomplete or damaged. Copy the whole `backpack://…`, or get a fresh one from `Manage → Setup Link` |
| `Tunnel is running but has not connected yet` | Iran firewall (tunnel port; `udp` for KCP), the tunnel not running on Iran, the address inside the link, or a filtered route. On the Iran server run `Manage → Status` and `Health Check` |
| `nothing is listening on 127.0.0.1:<port> on THIS server` | The tunnel is fine but there is no inbound. Create an inbound on that port in 3x-ui, or change the forwarded ports on the Iran server (`Manage → Edit → Change forwarded ports`) and update `TUNNEL_LINK` |
| The tunnel is connected but clients can't connect | The inbound port is wrong, UDP is needed but off, or the Iran firewall is closed (see [Port forwarding](#port-forwarding)) |
| Inbounds vanished after a deploy | No Volume (see [Persistence](#persistence)) |
| `sysctl` warnings in the tunnel log | Harmless; the container may not change kernel parameters |

---

## Technical details

<details>
<summary>File layout</summary>

| File | Role |
|---|---|
| `Dockerfile` | Starts from the 3x-ui image, installs `supervisor bash curl gawk`, downloads the BackPack binary, verifies it with `SHA256SUMS`, installs it at `/usr/local/bin/backpack`, and copies the scripts |
| `entrypoint.sh` | Prepares the 3x-ui database and port `2053`, runs `panel-config.sh`, then `exec supervisord` |
| `supervisord.conf` | Programs: `x-ui`, `backpack-webui`, `backpack-monitor`, and `tunnel-setup` (one-shot) |
| `panel-config.sh` | Writes `/etc/backpack/webui.json` from `PANEL_*` (atomically, mode `0600`) and generates random values when they are missing |
| `apply-link.sh` | Runs `backpack link apply` with `TUNNEL_LINK` (and `TUNNEL_NAME`, `TUNNEL_HOST`). Exit code `4` ("created but not connected yet") counts as success |
| `fake_systemctl.sh` | Stand-in for `systemctl` in a container without systemd |
| `fake_journalctl.sh` | Stand-in for `journalctl`; reads logs from `/var/log` so the panel's Logs page works |

</details>

<details>
<summary>How the fake systemctl works</summary>

BackPack manages its services with `systemctl` and `journalctl`, and the container has no systemd, so supervisord runs everything and these two scripts translate BackPack's commands:

- For each tunnel BackPack writes `/etc/systemd/system/backpack-<name>.service`. On `start`, `restart` or `enable --now`, a supervisord program is generated from that unit's `ExecStart` into `/etc/supervisor/custom.d/<name>.conf` and kept in sync with it.
- `is-active`, `is-enabled` and `show -p MainPID` are answered with `curl` over XML-RPC on `/run/supervisord.sock` (a few milliseconds instead of roughly 100 ms for `supervisorctl`), because the panel and the watchdog ask for the state constantly.
- `backpack-webui` and `backpack-monitor` are static programs: they are only started, stopped or restarted. A restart of the panel is run detached from the panel itself so it cannot be cut off halfway.
- `disable --now` on a tunnel being deleted also removes its program file, so it does not come back on the next boot.
- Logs are size-capped (1 MB per file) and `systemctl` calls are recorded in `/var/log/fake_systemctl.log`.

If you have a shell in the container (`railway ssh`):

```bash
supervisorctl status
tail -n 50 /var/log/backpack-webui.log
tail -n 50 /var/log/backpack-monitor.log
tail -n 50 /var/log/backpack-<name>.log
tail -n 50 /var/log/fake_systemctl.log
```

</details>

<details>
<summary>Running locally with Docker</summary>

```bash
git clone https://github.com/<your-username>/Backpack-Railway.git
cd Backpack-Railway

docker build -t backpack-railway .
# pin a version: docker build --build-arg BACKPACK_VERSION=v1.8.5 -t backpack-railway .

docker run --rm -it \
  -p 2053:2053 -p 7777:7777 \
  -e TUNNEL_LINK='backpack://...' \
  -e PANEL_PATH='k7Hq2mVx9TnPaw' \
  -e PANEL_PASSWORD='a-strong-password' \
  -v xui-data:/etc/x-ui \
  backpack-railway
```

Then `http://localhost:7777/k7Hq2mVx9TnPaw/` is the BackPack panel and `http://localhost:2053/` is 3x-ui. The image builds for `amd64` and `arm64`.

</details>

<details>
<summary>Limitations</summary>

- **No systemd.** Anything that relies on systemd timers, cron, `ufw` or `iptables` does not work or has no effect inside the container — for example PCK and "restart every N hours" (set that to `0`).
- **The filesystem is ephemeral.** Only what is in Variables or on a Volume survives.
- **One domain and one Target Port** per service, so only one of the two panels is reachable from outside at a time. If your Railway project offers a TCP Proxy, the second port can be exposed as well, but that path has no TLS and is not recommended for an admin panel.
- The BackPack panel was written mainly for the Iran server; here it runs on the foreign side and is useful for watching this tunnel's status and logs.
- A KCP tunnel has connected from Railway to an Iran server, but not every BackPack transport and feature has been tried in this container.

</details>

---

## License and credits

This repository does not redistribute BackPack or 3x-ui; it fetches them from their official sources at build time.

- **BackPack** is by **Amin Mohammadi (AminMGMT)**, released under the **GNU Affero General Public License v3.0**: <https://github.com/AminMGMT/BackPack>. The licence covers the code only; the name "BackPack" and its logo belong to the author ([TRADEMARK](https://github.com/AminMGMT/BackPack/blob/main/TRADEMARK.md)), and using them here does not make this repository official. Saying that this project is "based on" or "compatible with" BackPack is always allowed. As required by the [NOTICE](https://github.com/AminMGMT/BackPack/blob/main/NOTICE), the following line must stay unchanged (in forks as well):

```text
Based on BackPack by Amin Mohammadi (AminMGMT)
https://github.com/AminMGMT/BackPack
```

- **3x-ui** is by **MHSanaei** under GPL-3.0: <https://github.com/MHSanaei/3x-ui>.
- **supervisor** and **Alpine Linux** are in the image too, each under its own licence.
- The rest of BackPack's documentation is in the [main repository](https://github.com/AminMGMT/BackPack); every page there also has a Persian summary.