#!/usr/bin/env bash
# Deploys this project to Fly.io in one go: creates the app and its volume if they do not exist
# yet, sets the secrets, deploys exactly ONE machine, and checks that it stayed one.
# Safe to run again: the second time it only redeploys.
#
# The GitHub Action in .github/workflows/fly-deploy.yml runs this script; you can also run it
# yourself:  TUNNEL_LINK='backpack://...' FLY_APP_NAME=my-app bash fly-deploy.sh
#
# Needs flyctl (https://fly.io/docs/flyctl/install/) and a login (`fly auth login`) or FLY_API_TOKEN.
#
# Settings, all through environment variables:
#   TUNNEL_LINK       (required) the BackPack Setup Link, backpack://...
#   PANEL_PATH        secret path of the BackPack web panel          (recommended)
#   PANEL_PASSWORD    password of the BackPack web panel             (recommended)
#   TUNNEL_NAME       optional: name for the tunnel
#   TUNNEL_HOST       optional: Iran server address, if the link does not carry it
#   BACKPACK_VERSION  optional: BackPack version to build in, e.g. v1.8.5 (default: latest)
#   FLY_APP_NAME      app name: lowercase letters, digits and dashes, unique on all of Fly.io
#                     (in GitHub Actions the default is backpack-<repository owner>)
#   FLY_REGION        Fly region code (default: fra; an app that already has machines keeps their region)
#   FLY_ORG           organization the app is created in (default: personal)

set -euo pipefail

say() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

cd "$(dirname "$0")"

FLY=$(command -v flyctl || command -v fly || true)
[ -n "$FLY" ] || die "flyctl is not installed: https://fly.io/docs/flyctl/install/"
[ -f fly.toml ] || die "fly.toml is missing next to this script"
[ -n "${TUNNEL_LINK:-}" ] || die "TUNNEL_LINK is empty. Put your BackPack Setup Link (backpack://...) in it."

# --- settings --------------------------------------------------------------------------------
APP=${FLY_APP_NAME:-}
if [ -z "$APP" ] && [ -n "${GITHUB_REPOSITORY_OWNER:-}" ]; then
    owner=$(printf '%s' "$GITHUB_REPOSITORY_OWNER" | tr '[:upper:]' '[:lower:]' \
            | sed 's/[^a-z0-9]/-/g; s/--*/-/g' | cut -c1-40 | sed 's/^-//; s/-$//')
    APP="backpack-$owner"
fi
[ -n "$APP" ] || die "FLY_APP_NAME is not set. Choose a name (lowercase letters, digits, dashes) that is unique on Fly.io."
printf '%s' "$APP" | grep -Eq '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$' \
    || die "App name '$APP' is not valid: use lowercase letters, digits and dashes only (at most 63 characters)."

REGION=${FLY_REGION:-fra}
printf '%s' "$REGION" | grep -Eq '^[a-z]{3}$' || die "Region '$REGION' is not a Fly region code (three letters, e.g. fra)."
REGION_GIVEN=no
if [ -n "${FLY_REGION:-}" ]; then REGION_GIVEN=yes; fi
ORG=${FLY_ORG:-personal}

say "App: $APP   region: $REGION   organization: $ORG"

# --- 1. the app --------------------------------------------------------------------------------
if "$FLY" status --app "$APP" >/dev/null 2>&1; then
    say "App $APP already exists."
else
    say "Creating app $APP ..."
    "$FLY" apps create "$APP" --org "$ORG" \
        || die "Could not create the app. The name may already be taken on Fly.io (try another FLY_APP_NAME), or the token cannot create apps: use an organization token (fly tokens create org)."
fi

# --- region of the machines the app already has ---------------------------------------------------
# A volume only works in the same region as its machine. For an app that already exists (say it
# was created by `fly launch` in iad), follow its machines instead of the default region.
machine_regions() {
    "$FLY" machines list --app "$APP" --json 2>/dev/null | python3 -c '
import json, sys
try:
    print(" ".join(sorted({m["region"] for m in json.load(sys.stdin) if m.get("region")})))
except Exception:
    pass' 2>/dev/null || true
}
if command -v python3 >/dev/null 2>&1; then
    existing=$(machine_regions)
    if [ -n "$existing" ]; then
        if [ "$REGION_GIVEN" = no ]; then
            REGION=${existing%% *}
            say "The app already has a machine in $existing; using region $REGION for the volume."
        elif ! grep -qw "$REGION" <<<"$existing"; then
            die "The app $APP already has a machine in region: $existing, but FLY_REGION is $REGION. The volume must be in the same region as the machine. Either set FLY_REGION to ${existing%% *} (or leave it empty), or remove the old machine first:  fly machine list -a $APP   then   fly machine destroy <id> --force -a $APP"
        fi
    fi
fi

# --- 2. the volume that keeps the 3x-ui database --------------------------------------------------
volumes=$("$FLY" volumes list --app "$APP" 2>/dev/null || true)
if grep -qw xui_data <<<"$volumes"; then
    say "Volume xui_data already exists."
else
    say "Creating volume xui_data in $REGION ..."
    "$FLY" volumes create xui_data --region "$REGION" --size 1 --yes --app "$APP"
fi

# --- 3. secrets (staged: they are applied by the deploy below) -----------------------------------
secrets=("TUNNEL_LINK=$TUNNEL_LINK")
for name in TUNNEL_NAME TUNNEL_HOST PANEL_PATH PANEL_PASSWORD; do
    if [ -n "${!name:-}" ]; then secrets+=("$name=${!name}"); fi
done
say "Setting secrets: $(printf '%s\n' "${secrets[@]}" | cut -d= -f1 | paste -sd, -)"
"$FLY" secrets set --stage --app "$APP" "${secrets[@]}" >/dev/null
if [ -z "${PANEL_PATH:-}" ] || [ -z "${PANEL_PASSWORD:-}" ]; then
    say "NOTE: PANEL_PATH / PANEL_PASSWORD are not both set. The BackPack panel then gets a random path and"
    say "      password at every start, printed once in the logs (fly logs). Set both to keep them."
fi

# --- 4. deploy exactly one machine --------------------------------------------------------------------
# A copy of fly.toml carries your app name and region, so the file itself stays untouched.
CFG=fly.deploy.toml
trap 'rm -f "$CFG"' EXIT
sed -e "s|^app = .*|app = \"$APP\"|" -e "s|^primary_region = .*|primary_region = \"$REGION\"|" fly.toml > "$CFG"
if ! grep -q "^app = \"$APP\"\$" "$CFG" || ! grep -q "^primary_region = \"$REGION\"\$" "$CFG"; then
    die "fly.toml must keep its top-level 'app = ...' and 'primary_region = ...' lines."
fi

args=(deploy --config "$CFG" --app "$APP" --remote-only --ha=false)
if [ -n "${BACKPACK_VERSION:-}" ]; then args+=(--build-arg "BACKPACK_VERSION=$BACKPACK_VERSION"); fi
say "Deploying ..."
"$FLY" "${args[@]}"

# --- 5. exactly one machine ---------------------------------------------------------------------------------
# Two machines with one TUNNEL_LINK take the tunnel away from each other, and each would have
# its own 3x-ui database (so you would be logged out of the panel all the time).
count_machines() {
    "$FLY" machines list --app "$APP" --json | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))'
}
if command -v python3 >/dev/null 2>&1; then
    n=$(count_machines)
    if [ "$n" -gt 1 ]; then
        say "The app has $n machines; keeping one ..."
        "$FLY" scale count 1 --app "$APP" --yes
        n=$(count_machines)
        [ "$n" -eq 1 ] || die "The app still has $n machines. Run: fly machine list -a $APP  and destroy the extra ones."
    fi
else
    say "NOTE: python3 not found, could not count machines. Check: fly machine list -a $APP (it must show ONE)."
fi

# Which panel the public address shows depends on internal_port in fly.toml (7777 or 2053).
PORT=$(sed -n 's/^[[:space:]]*internal_port[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*/\1/p' fly.toml | head -n 1)
say ""
say "Done."
if [ "$PORT" = 2053 ]; then
    say "  3x-ui panel    : https://$APP.fly.dev/   (first login: admin / admin - change it at once)"
    say "  BackPack panel : not public. Run  fly proxy 7777:7777 -a $APP  and open http://localhost:7777/<PANEL_PATH>/"
else
    say "  BackPack panel : https://$APP.fly.dev/<PANEL_PATH>/"
    say "  3x-ui panel    : not public. Run  fly proxy 2053:2053 -a $APP  and open http://localhost:2053/"
    say "                   (first login: admin / admin - change it at once)"
fi
say "  Logs           : fly logs -a $APP"
