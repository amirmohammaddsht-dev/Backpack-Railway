<p align="center"><b>English</b> · <a href="README_FA.md">فارسی</a></p>

# Backpack-Railway

Run the **BackPack** tunnel and the **3x-ui** panel on **Railway** or **Fly.io** in a few clicks: **fork** this project, deploy your fork, and put your tunnel's setup link in one variable. That's it.

> Based on BackPack by Amin Mohammadi (AminMGMT)
> https://github.com/AminMGMT/BackPack

This repository is **unofficial** and is not BackPack itself: at build time it only downloads the official BackPack release binary and verifies its checksum. 3x-ui comes from the official `ghcr.io/mhsanaei/3x-ui` image. See [License and credits](#license-and-credits).

| Platform | Status | Start here |
|---|---|---|
| **Railway** | Works out of the box | [Install in 5 steps](#install-in-5-steps) |
| **Fly.io** | Works with the included GitHub Action or `fly-deploy.sh` | [Fly.io](#flyio) |
| **Blitz.cloud** | Not allowed by its terms | [Blitz.cloud](#blitzcloud) |

## Contents

- [What does this project do?](#what-does-this-project-do)
- [Install in 5 steps](#install-in-5-steps)
- [Updating your fork](#updating-your-fork)
- [Variables](#variables)
- [Port forwarding](#port-forwarding)
- [Persistence](#persistence)
- [Fly.io and Blitz.cloud](#flyio-and-blitzcloud)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Technical details](#technical-details)
- [License and credits](#license-and-credits)

---

## What does this project do?

BackPack is a tunnel between an **Iran server** and a **foreign (kharej) server**. Here the foreign server is this container, running on Railway or Fly.io. You create the tunnel on the Iran server, copy its **Setup Link** (`backpack://…`), and hand it to the platform. The container then connects to Iran by itself and keeps the tunnel up. Because the container is the one that opens the connection, the platform does not have to expose any port for the tunnel.

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
               ║  BackPack tunnel — the container (Railway / Fly.io) dials OUT to Iran
               ▼
 Container ─▶ 127.0.0.1:<port> ─▶ x-ui inbound
```

---

## Install in 5 steps

> This is the Railway route. On Fly.io follow [Fly.io](#flyio) instead.

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
→ Forwarded Ports      e.g. 443=127.0.0.1:2002   (see "Port forwarding")
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
- **3x-ui:** temporarily set the domain's Target Port to `2053` and open `https://<your-railway-domain>/`. The first time, both username and password are `admin`; **change them immediately.** Create an **inbound whose port is exactly the one you put in the Iran server's Forwarded Ports** (`2002` in the example). The tunnel delivers traffic to `127.0.0.1:2002` inside the container, and if nothing listens there the log says `nothing is listening on 127.0.0.1:2002 on THIS server`.
- **Clients:** in the user's client config, use the **Iran server's IP** and the **public port** (e.g. `443`), not the Railway address.

---

## Updating your fork

When this repository changes, open your fork on GitHub and click **Sync fork → Update branch**. By default Railway builds and deploys again on every new commit.

Each build also fetches the latest official BackPack release. To stay on one version, add `BACKPACK_VERSION=v1.8.5` to Variables (the version this project was tested with). If Railway does not pass that variable to the build, change the default of `ARG BACKPACK_VERSION` in your fork's `Dockerfile` instead.

On Fly.io, after **Sync fork** run the *Deploy to Fly.io* workflow again (or set `FLY_AUTODEPLOY`); see [Fly.io](#flyio).

---

## Variables

Set them in **Railway → Variables**. On Fly.io, `TUNNEL_*` and `PANEL_PATH` / `PANEL_PASSWORD` are Fly secrets (the GitHub Action and `fly-deploy.sh` set them for you), `BACKPACK_VERSION` is a build argument, and `PANEL_PORT` must match `internal_port` in `fly.toml`.

| Variable | Required? | Default | Description |
|---|---|---|---|
| `TUNNEL_LINK` | To build the tunnel | empty | The full Setup Link `backpack://…`. If empty, no tunnel is created. **It contains the tunnel's token; keep it secret.** |
| `TUNNEL_NAME` | No | name suggested by the link | Overrides the tunnel name |
| `TUNNEL_HOST` | No | empty | Iran server address; only needed if the link does not carry it |
| `PANEL_PATH` | Recommended | random | Secret path of the BackPack panel, 8–64 characters from `A-Z a-z 0-9 _ -` |
| `PANEL_PASSWORD` | Recommended | random | BackPack panel password, 8–128 characters |
| `PANEL_PORT` | No | `7777` | Port of the BackPack panel. The Railway domain's Target Port (or `internal_port` in `fly.toml`) must match |
| `BACKPACK_VERSION` | No | `latest` | BackPack version used at build time, e.g. `v1.8.5` |

- An invalid `PANEL_*` value is ignored and the reason is printed in the log.
- If you leave `PANEL_PATH` or `PANEL_PASSWORD` unset, a **new value is generated on every deploy or restart** and printed once in the log (on Fly.io: `fly logs`), between two `=====` lines.
- Every deploy (and every restart) starts with a fresh container filesystem and rebuilds the tunnel from `TUNNEL_LINK`. If you change something on the Iran server (ports, transport), get a new link from `Manage → Setup Link`, put it in `TUNNEL_LINK` and deploy again (on Fly.io: `fly secrets set TUNNEL_LINK='backpack://...' -a <app>`, which redeploys the machine so the new value takes effect).

---

## Port forwarding

On the Iran server, **Forwarded Ports** decides which public port goes to which port **inside the container**:

| Entry | Meaning |
|---|---|
| `443=127.0.0.1:2002` | Users connect to Iran:`443`; the tunnel delivers to `127.0.0.1:2002` in the container |
| `443=127.0.0.1:2002, 8443=127.0.0.1:2003` | Several inbounds over one tunnel |
| `443=127.0.0.1:2002\|127.0.0.1:2003` | Two backends, balanced and health-checked |
| `10000-10009` | A range; each port to the same port |

> **A bare `443` does not mean "any port".** It means something must really listen on `127.0.0.1:443` inside the container. If your inbound is on `2002`, write `443=127.0.0.1:2002`.

- An inbound's port must not be `2053` (3x-ui panel), `2096` (3x-ui subscription server) or `7777` (BackPack panel).
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

On **Fly.io** it is the same, and worse: the filesystem is also reset every time the machine restarts or is stopped, not only on deploys. The `fly.toml` in this repository mounts a Fly volume named `xui_data` on `/etc/x-ui`, and `fly-deploy.sh` creates it for you (in the region of the machine). Without that volume the 3x-ui database is lost at every restart and the panel goes back to `admin` / `admin`.

On every platform, `entrypoint.sh` sets the 3x-ui panel port back to `2053` at each start; the rest of what is in the volume (users, inbounds, admin password) is kept.

---

## Fly.io and Blitz.cloud

Railway needs nothing special. On other platforms the tunnel can drop because the platform stops the app, or because its rules do not allow this kind of program.

### Fly.io

Fly stops a machine that receives no incoming web traffic, and a first deploy creates **two machines** by default. Both break this project: the tunnel only dials out, so Fly sees an idle app; and two machines with one `TUNNEL_LINK` take the tunnel away from each other, each with its own empty 3x-ui database. The `fly.toml` in this repository turns both off (no auto-stop, one machine, 512 MB, a volume on `/etc/x-ui`), and `fly-deploy.sh` does the whole deployment for you.

#### Automatic: GitHub Actions (recommended)

1. **Fork** this repository and enable Actions in your fork (the **Actions** tab, then *I understand my workflows, go ahead and enable them*).
2. Create a Fly.io token that is allowed to create apps. On your computer, with [flyctl](https://fly.io/docs/flyctl/install/) installed and `fly auth login` done:

   ```bash
   fly tokens create org -o personal -x 8760h
   ```

   Copy the **whole** output. The token can manage everything in that Fly organization, so keep it only in this repository's secrets.
3. In your fork open **Settings → Secrets and variables → Actions → New repository secret** and add:

   | Secret | Value |
   |---|---|
   | `FLY_API_TOKEN` | the token from step 2 |
   | `TUNNEL_LINK` | your BackPack Setup Link |
   | `PANEL_PATH` | a secret path for the BackPack panel |
   | `PANEL_PASSWORD` | a strong password |

4. Open **Actions → Deploy to Fly.io → Run workflow**. It creates the app (`backpack-<your GitHub name>`) and the volume, sets the secrets, deploys one machine and checks that it stays one. The end of the log shows your addresses.

Optional **variables** (the *Variables* tab of the same page): `FLY_APP_NAME` (the app name; it must be unique on Fly.io), `FLY_REGION` (default `fra`; if the app already exists, the region of its machine is used, and a different value stops the script with an explanation, because a volume only works in its machine's region), `FLY_ORG` (default `personal`), `TUNNEL_NAME`, `TUNNEL_HOST`, `BACKPACK_VERSION`, and `FLY_AUTODEPLOY` = `true` to redeploy on every push. After **Sync fork**, run the workflow again (or use `FLY_AUTODEPLOY`).

#### From your computer

```bash
export TUNNEL_LINK='backpack://...' PANEL_PATH='k7Hq2mVx9TnPaw' PANEL_PASSWORD='choose-a-strong-password'
export FLY_APP_NAME=my-unique-app-name      # lowercase letters, digits, dashes
fly auth login
bash fly-deploy.sh
```

Running it again just redeploys.

#### Afterwards

- The public address `https://<app>.fly.dev/<PANEL_PATH>/` shows the BackPack panel.
- 3x-ui is not public. Run `fly proxy 2053:2053 -a <app>` and open `http://localhost:2053/`. To expose it instead, change `internal_port` to `2053` in `fly.toml`; then change the first-login `admin` / `admin` at once, and open the BackPack panel with `fly proxy 7777:7777 -a <app>`.
- Fly's own **Launch from GitHub** page writes a separate `fly.toml` into a new branch (`flyio-new-files`) that can change the region and the `internal_port`. Do not merge that branch; use the workflow or `fly-deploy.sh`.
- The script checks the machine count for you. If you ever see two machines in `fly machine list`, run `fly scale count 1`.
- If you already have an app with two machines and no volume, the cleanest fix is `fly apps destroy <app>` and then running the workflow again. Nothing is lost that a redeploy would not have wiped anyway.

<details>
<summary>Doing it by hand instead</summary>

Put your own unique app name on the `app` line of `fly.toml`, then:

```bash
fly apps create <your-app-name>                     # the same name as the `app` line in fly.toml
fly volumes create xui_data --size 1 --region fra    # the region in fly.toml
fly secrets set TUNNEL_LINK='backpack://...' PANEL_PATH='k7Hq2mVx9TnPaw' PANEL_PASSWORD='choose-a-strong-password'
fly deploy --ha=false
fly machine list                                     # must show exactly ONE machine
```

</details>

### Blitz.cloud

**Do not use blitz.cloud for this.** Its [terms](https://blitz.cloud/terms/) (section 8, updated 16 November 2026) forbid running "a VPN, proxy or tunnel server that forwards internet traffic, such as Xray, V2Ray, sing-box", and an automated check pauses an app that contains such a program, without a person reviewing it first. A paid plan does not change that. If an app keeps going offline there, look for the email blitz.cloud sends when it pauses an app.


---

## Security

- **Change the 3x-ui password right away** (first boot is `admin` / `admin`). The Railway domain is public and gets scanned (on Fly.io only if you published 3x-ui). You can also change the panel's Web Base Path in 3x-ui's settings.
- **Keep `TUNNEL_LINK` only in Railway Variables or in Fly / GitHub secrets** — not in your fork, a chat, an issue or a log. Anyone who has it can connect to your Iran server in your place. If it leaks, change the token on the Iran server and get a new link.
- The BackPack panel **lives under a secret path and everything outside it returns `404`.** Pick `PANEL_PATH` as randomly and as long as a password. Under **Settings → Security** you can also turn on two-factor sign-in.
- After 5 wrong passwords, sign-in is blocked for 10 minutes. Behind a platform proxy (Railway, Fly.io) all visitors can appear to come from one IP address, so a few failed attempts can lock everyone out for a while.
- Do **not** turn on the **HTTPS** option in the BackPack panel's settings; the panel serves plain HTTP and Railway or Fly.io provides the TLS.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| The Railway address returns `404` without a path | Normal. Open `https://<domain>/<PANEL_PATH>/` |
| `502` or "Application failed to respond" | Set the domain's Target Port to `7777` (BackPack panel) or `2053` (3x-ui); keep the BackPack panel's HTTPS off; check the logs |
| The 3x-ui login page shows instead of the BackPack panel | Target Port is `2053`; set it to `7777` |
| I don't know the panel path or password | Set `PANEL_PATH` and `PANEL_PASSWORD` in Variables (Railway) or with `fly secrets set` (Fly.io) and deploy again. If they are not set, the generated ones are printed once in the log |
| "too many failed attempts" | Sign-in lockout; wait 10 minutes |
| `PANEL_PATH ignored` or `PANEL_PASSWORD ignored` | The value is invalid; fix its length and characters as in [Variables](#variables) |
| `TUNNEL_LINK is not set` | The variable is empty |
| `link apply failed (exit N)` | The link is incomplete or damaged. Copy the whole `backpack://…`, or get a fresh one from `Manage → Setup Link` |
| `Tunnel is running but has not connected yet` | Iran firewall (tunnel port; `udp` for KCP), the tunnel not running on Iran, the address inside the link, or a filtered route. On the Iran server run `Manage → Status` and `Health Check` |
| `nothing is listening on 127.0.0.1:<port> on THIS server` | The tunnel is fine but there is no inbound. Create an inbound on that port in 3x-ui, or change the forwarded ports on the Iran server (`Manage → Edit → Change forwarded ports`) and update `TUNNEL_LINK` |
| The tunnel is connected but clients can't connect | The inbound port is wrong, UDP is needed but off, or the Iran firewall is closed (see [Port forwarding](#port-forwarding)) |
| Inbounds vanished after a deploy | No Volume (see [Persistence](#persistence)) |
| `Creating new database with admin/admin` in the log after a restart | The 3x-ui database was not on a persistent volume (see [Persistence](#persistence)) |
| `securecookie: the value is not valid` in the 3x-ui log, and you keep getting logged out | The browser holds a login cookie signed by an older 3x-ui database. It happens when the database was lost or two machines are running (Fly.io): make sure there is exactly one machine and the `xui_data` volume, then clear the site's cookies and sign in again |
| `autostopping machine … excess capacity` in `fly logs` | Fly stopped an idle machine: the app was not deployed with this repository's `fly.toml` (`auto_stop_machines` must be `"off"`). Redeploy with the workflow or `fly-deploy.sh` |
| `needs volumes with name 'xui_data'` when deploying | There is no `xui_data` volume in the machine's region: `fly volumes create xui_data --region <region shown by fly machine list> --size 1 -a <app>` |
| Fly.io shows two machines | `fly scale count 1 -a <app>` (the script does this itself) |
| The tunnel keeps dropping and reconnecting | Only one container may use a given `TUNNEL_LINK`; a second one takes the connection from the first. Railway: Replicas = 1; Fly.io: one machine; stop any old deployment still running elsewhere |
| `sysctl` warnings in the tunnel log | Harmless; the container may not change kernel parameters |

---

## Technical details

<details>
<summary>File layout</summary>

| File | Role |
|---|---|
| `Dockerfile` | Starts from the 3x-ui image, installs `supervisor bash curl gawk`, downloads the BackPack binary, verifies it with `SHA256SUMS`, installs it at `/usr/local/bin/backpack`, and copies the scripts |
| `entrypoint.sh` | Prepares the 3x-ui database and port `2053` (set again at every start), runs `panel-config.sh`, then `exec supervisord` |
| `supervisord.conf` | Programs: `x-ui`, `backpack-webui`, `backpack-monitor`, and `tunnel-setup` (one-shot) |
| `panel-config.sh` | Writes `/etc/backpack/webui.json` from `PANEL_*` (atomically, mode `0600`) and generates random values when they are missing |
| `apply-link.sh` | Runs `backpack link apply` with `TUNNEL_LINK` (and `TUNNEL_NAME`, `TUNNEL_HOST`). Exit code `4` ("created but not connected yet") counts as success |
| `fake_systemctl.sh` | Stand-in for `systemctl` in a container without systemd |
| `fake_journalctl.sh` | Stand-in for `journalctl`; reads logs from `/var/log` so the panel's Logs page works |
| `fly.toml` | Fly.io settings: one machine, no auto-stop, a volume on `/etc/x-ui`. Railway ignores it |
| `fly-deploy.sh` | One-command Fly.io deployment (app, volume, secrets, deploy, one-machine check); run by the workflow or by hand |
| `.github/workflows/fly-deploy.yml` | The *Deploy to Fly.io* GitHub Action; it runs `fly-deploy.sh` |
| `.dockerignore` | Keeps the docs and the Fly files out of the image |

</details>

<details>
<summary>How the fake systemctl works</summary>

BackPack manages its services with `systemctl` and `journalctl`, and the container has no systemd, so supervisord runs everything and these two scripts translate BackPack's commands:

- For each tunnel BackPack writes `/etc/systemd/system/backpack-<name>.service`. On `start`, `restart` or `enable --now`, a supervisord program is generated from that unit's `ExecStart` into `/etc/supervisor/custom.d/<name>.conf` and kept in sync with it.
- `is-active`, `is-enabled` and `show -p MainPID` are answered with `curl` over XML-RPC on `/run/supervisord.sock` (a few milliseconds instead of roughly 100 ms for `supervisorctl`), because the panel and the watchdog ask for the state constantly.
- `backpack-webui` and `backpack-monitor` are static programs: they are only started, stopped or restarted. A restart of the panel is run detached from the panel itself so it cannot be cut off halfway.
- `disable --now` on a tunnel being deleted also removes its program file, so it does not come back on the next boot.
- Logs are size-capped (1 MB per file) and `systemctl` calls are recorded in `/var/log/fake_systemctl.log`.

If you have a shell in the container (`railway ssh`, or `fly ssh console -a <app>` on Fly.io):

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
- **The filesystem is ephemeral** (on Fly.io across restarts too). Only what is in Variables / secrets or on a Volume survives.
- **The 3x-ui panel port is fixed at `2053`.** It is set again at every start.
- **One domain and one Target Port** per service (on Fly.io: one `internal_port` in `fly.toml`), so only one of the two panels is reachable from outside at a time. If your Railway project offers a TCP Proxy, the second port can be exposed as well, but that path has no TLS and is not recommended for an admin panel.
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
