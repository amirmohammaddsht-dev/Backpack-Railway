#!/bin/bash
# systemctl stand-in for a container that has no systemd. BackPack drives its services with a
# handful of systemctl verbs; this maps them onto supervisord.
#
#   tunnels      BackPack writes /etc/systemd/system/backpack-<name>.service. start, restart and
#                `enable --now` turn its ExecStart into a supervisord program in custom.d, and keep
#                it in step with the unit file, so an edited tunnel gets its new command.
#   panel/monitor  are programs of supervisord.conf itself ("static"). They are only started,
#                stopped and restarted here, never redefined.

MAIN_CONF=/etc/supervisor/conf.d/supervisord.conf
CONF_DIR=/etc/supervisor/custom.d
UNIT_DIR=/etc/systemd/system
SOCK=/run/supervisord.sock
LOG=/var/log/fake_systemctl.log

ORIG=("$@")
NOW=false
NOBLOCK=false
PROP=""
ARGS=()
while [ $# -gt 0 ]; do
    case $1 in
        --now)      NOW=true ;;
        --no-block) NOBLOCK=true ;;
        -p)         PROP=$2; shift ;;
        -*)         ;;                       # --value, --no-pager, --quiet ... mean nothing here
        *)          ARGS+=("$1") ;;
    esac
    shift
done

COMMAND=${ARGS[0]}
NAMES=()
for u in "${ARGS[@]:1}"; do NAMES+=("$(basename "$u" .service)"); done
NAME=${NAMES[0]}

# --- reading state: ask supervisord over its socket ---------------------------------------------
# curl answers in ~5 ms; starting supervisorctl (a Python program) costs ~100 ms of CPU, and the
# panel and the monitor ask for the state of every service every few seconds.
# Only bash builtins after the curl: every extra process is paid for on each poll.
info() {    # <name> -> the program's reply on one line; empty if supervisord does not know it
    local r
    r=$(curl -s --max-time 5 --unix-socket "$SOCK" -H 'Content-Type: text/xml' \
        -d "<?xml version=\"1.0\"?><methodCall><methodName>supervisor.getProcessInfo</methodName><params><param><value><string>$1</string></value></param></params></methodCall>" \
        http://localhost/RPC2 2>/dev/null) || return 1
    r=${r//$'\n'/}
    [[ $r == *'<fault>'* ]] && return 1
    printf '%s' "$r"
}
field() {   # <reply> <member> <type>
    local re="<name>$2</name><value><$3>([^<]*)</$3>"
    [[ $1 =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}
state() { field "$(info "$1")" statename string; }

case "$COMMAND" in
    is-active)
        case "$(state "$NAME")" in
            # STARTING counts: right after `enable --now` supervisord says STARTING for about a
            # second, and BackPack would otherwise call a healthy tunnel "did not start".
            RUNNING|STARTING) echo active; exit 0 ;;
            *)                echo inactive; exit 3 ;;
        esac ;;
    is-enabled)
        if [ -n "$(info "$NAME")" ]; then echo enabled; exit 0; else echo disabled; exit 1; fi ;;
    show)
        [ "$PROP" = MainPID ] && { pid=$(field "$(info "$NAME")" pid int); echo "${pid:-0}"; }
        exit 0 ;;
    start|enable|stop|disable|restart|try-restart|reload-or-restart) ;;
    *)  exit 0 ;;                            # daemon-reload, reset-failed, status ...
esac

# --- changing state ---------------------------------------------------------------------------------
# `--no-block` asks for exactly this, and the web panel restarting itself needs it too: the caller
# is the process being restarted, and a restart that is cut off halfway leaves the panel stopped.
detach=$NOBLOCK
case "$COMMAND" in
    restart|try-restart|reload-or-restart|stop|disable)
        for n in "${NAMES[@]}"; do [ "$n" = backpack-webui ] && detach=true; done ;;
esac
if [ "$detach" = true ] && [ -z "$FAKE_SYSTEMCTL_DETACHED" ]; then
    FAKE_SYSTEMCTL_DETACHED=1 setsid "$0" "${ORIG[@]}" </dev/null >/dev/null 2>&1 &
    exit 0
fi

log() {
    echo "[$(date '+%F %T')] $*" >> "$LOG"
    # the log lives on the container's disk: keep it small
    if [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 131072 ]; then
        tail -n 300 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
    fi
}
sup() { supervisorctl "$@" >> "$LOG" 2>&1; }
is_static() { grep -q "^\[program:$1\]" "$MAIN_CONF" 2>/dev/null; }

# Rebuilds a tunnel's supervisord program from its unit file.
# Returns 0 if the program changed or is new, 1 if it was already up to date, 2 if no unit file.
write_conf() {
    local name=$1 unit="$UNIT_DIR/$1.service" conf="$CONF_DIR/$1.conf" exec_start work_dir tmp
    [ -f "$unit" ] || return 2
    exec_start=$(sed -n 's/^ExecStart=\(.*\)/\1/p' "$unit" | head -n 1 | xargs)
    work_dir=$(sed -n 's/^WorkingDirectory=\(.*\)/\1/p' "$unit" | head -n 1 | xargs)
    mkdir -p "$CONF_DIR"
    tmp=$(mktemp)
    {
        echo "[program:$name]"
        echo "command=$exec_start"
        [ -n "$work_dir" ] && echo "directory=$work_dir"
        echo "autostart=true"
        echo "autorestart=true"
        # The unit says Restart=always. Without this, supervisord gives up on a program that
        # fails to start 3 times in a row, and a tunnel whose server is briefly unreachable
        # would stay down for good.
        echo "startretries=1000000"
        echo "stdout_logfile=/var/log/$name.log"
        echo "stdout_logfile_maxbytes=1MB"
        echo "stdout_logfile_backups=0"
        echo "stderr_logfile=/var/log/$name.err.log"
        echo "stderr_logfile_maxbytes=1MB"
        echo "stderr_logfile_backups=0"
    } > "$tmp"
    if cmp -s "$tmp" "$conf"; then rm -f "$tmp"; return 1; fi
    mv "$tmp" "$conf"
    return 0
}

start_unit() {
    local name=$1
    if ! is_static "$name"; then
        write_conf "$name"
        case $? in
            0) sup reread; sup update ;;
            2) [ -n "$(info "$name")" ] || { log "start $name: no unit file and no program"; return; } ;;
        esac
    fi
    sup start "$name"
}

restart_unit() {
    local name=$1
    if ! is_static "$name"; then
        write_conf "$name"
        case $? in
            0) sup reread; sup update ;;
            2) [ -n "$(info "$name")" ] || { log "restart $name: no unit file and no program"; return; } ;;
        esac
    fi
    sup restart "$name"
}

stop_unit() { sup stop "$1"; }

# `disable --now` on a tunnel being deleted: forget the program, or it would come back at the next boot.
forget_unit() {
    is_static "$1" && return
    rm -f "$CONF_DIR/$1.conf"
    sup reread; sup update
}

log "systemctl ${ORIG[*]}"
for n in "${NAMES[@]}"; do
    case "$COMMAND" in
        start)                         start_unit "$n" ;;
        enable)                        [ "$NOW" = true ] && start_unit "$n" ;;
        stop)                          stop_unit "$n" ;;
        disable)                       [ "$NOW" = true ] && { stop_unit "$n"; forget_unit "$n"; } ;;
        restart|reload-or-restart)     restart_unit "$n" ;;
        try-restart)                   case "$(state "$n")" in RUNNING|STARTING) restart_unit "$n" ;; esac ;;
    esac
done
exit 0