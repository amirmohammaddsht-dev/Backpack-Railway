#!/bin/bash
# Prepares /etc/backpack/webui.json for `backpack --webui` (the BackPack web panel).
#
# Railway containers start from scratch on every deploy, so without these variables the
# panel would invent a new secret path and password each time.
#
#   PANEL_PATH      secret URL segment the whole panel lives under (A-Z a-z 0-9 _ -, 8-64 chars)
#   PANEL_PASSWORD  login password (8-128 characters)
#   PANEL_PORT      port the panel listens on (default 7777) - the Railway domain must target it
#
# A value that is not set (or is invalid) keeps what webui.json already holds, and failing
# that is generated. Every other field in an existing webui.json (second factor, ...) is kept.
# Values arrive through the environment, never on a command line, so they stay out of `ps`.

exec python3 - <<'PY'
import json, os, re, secrets, sys

CFG = "/etc/backpack/webui.json"
# BackPack's own alphabet for path segments: no 0/O and no 1/l/I, so nothing is misread.
ALPHABET = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"


def say(msg):
    print("[panel] " + msg, flush=True)


def load():
    try:
        with open(CFG) as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except FileNotFoundError:
        return {}
    except (OSError, ValueError):
        os.replace(CFG, CFG + ".bad")
        say("webui.json was unreadable - moved to webui.json.bad, starting a fresh one")
        return {}


def env(name):
    value = os.environ.get(name, "")
    return value if value.strip() else None


def generate(n):
    return "".join(secrets.choice(ALPHABET) for _ in range(n))


cfg = load()
generated = {}

# --- path -----------------------------------------------------------------
path = env("PANEL_PATH")
if path is not None:
    path = path.strip().strip("/")
    if re.fullmatch(r"[A-Za-z0-9_-]{8,64}", path):
        cfg["base_path"] = path
    else:
        say("PANEL_PATH ignored: use 8-64 characters from A-Z a-z 0-9 _ - "
            "(the path is the only thing hiding the panel from scanners)")
if not str(cfg.get("base_path", "")).strip("/"):
    cfg["base_path"] = generate(14)
    generated["path"] = cfg["base_path"]

# --- password ---------------------------------------------------------------
password = env("PANEL_PASSWORD")
if password is not None:
    if 8 <= len(password) <= 128 and not re.search(r"[\x00-\x1f\x7f]", password):
        cfg["password"] = password
    else:
        say("PANEL_PASSWORD ignored: use 8-128 characters, no control characters")
if not cfg.get("password"):
    cfg["password"] = generate(12)
    generated["password"] = cfg["password"]

# --- port -------------------------------------------------------------------
port = env("PANEL_PORT")
if port is not None:
    if port.strip().isdigit() and 1 <= int(port) <= 65535:
        cfg["port"] = int(port)
    else:
        say("PANEL_PORT ignored: it must be a number between 1 and 65535")
cfg.setdefault("port", 7777)

# --- write (atomic, owner-only: it holds the password) ----------------------
os.makedirs(os.path.dirname(CFG), exist_ok=True)
tmp = CFG + ".tmp"
fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    json.dump(cfg, f, indent=2)
os.replace(tmp, CFG)

say("web panel on port %s under /%s/ (anything outside that path answers 404)"
    % (cfg["port"], cfg["base_path"]))
if generated:
    say("=============================================================")
    if "path" in generated:
        say(" PATH:     /%s/" % generated["path"])
    if "password" in generated:
        say(" PASSWORD: %s" % generated["password"])
    say(" Generated for this deploy only. Set PANEL_PATH / PANEL_PASSWORD in")
    say(" Railway Variables to keep them across deploys.")
    say("=============================================================")
sys.stdout.flush()
PY
