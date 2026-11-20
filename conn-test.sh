#!/bin/bash
# Runs once under supervisord (program: connection-test).
# Runs BackPack's Connection Test from the link in $TEST_LINK and prints the verdict in the log.
#
#   TEST_LINK  (optional)  the Connection Test link, backpack://t.... , or the whole
#                          `sudo backpack link apply 'backpack://t....'` line printed with it
#
# How to get the link: on the Iran server run `sudo backpack` and choose "0) Connection Test".
# That server must keep the test open while this container runs: the test builds a few test
# tunnels between the two servers for several minutes and the link only works until it ends.
# Nothing is installed here and no tunnel is changed - it is a measurement only.
#
# The link is never printed (it carries the test's secret).

LOG="[connection-test]"

if [ -z "${TEST_LINK:-}" ]; then
    echo "$LOG TEST_LINK is not set - no connection test will run."
    exit 0
fi

# Tells whether a base64url text decodes to what BackPack accepts as a Connection Test link:
# more than 15 bytes (version, port and secret come first) and version 1 or 2.
valid_token() {
    local t=$1 pad bytes
    case $(( ${#t} % 4 )) in 0) pad='' ;; 2) pad='==' ;; 3) pad='=' ;; *) return 1 ;; esac
    bytes=$(printf '%s%s' "$t" "$pad" | tr '_-' '/+' | base64 -d 2>/dev/null | od -An -tu1 -v | tr -s ' \n' ' ')
    read -ra b <<<"$bytes"
    [ "${#b[@]}" -gt 15 ] && { [ "${b[0]}" = 1 ] || [ "${b[0]}" = 2 ]; }
}

# Look for the link without printing it: first as it stands (quotes and the words around it
# are left out), then with all whitespace removed, in case it was wrapped over several lines
# when it was pasted.
flat=$(printf '%s' "$TEST_LINK" | tr -d '[:space:]')
case "$flat" in
    *backpack://t.*) ;;
    *backpack://*)
        echo "$LOG TEST_LINK holds a Setup Link, not a Connection Test link."
        echo "$LOG A Setup Link goes into TUNNEL_LINK; TEST_LINK is for the link of 'sudo backpack' -> 0) Connection Test (it starts with backpack://t.)."
        exit 1 ;;
    *)
        echo "$LOG TEST_LINK does not contain a Connection Test link (backpack://t....)."
        echo "$LOG Start the test on the Iran server ('sudo backpack' -> 0) Connection Test) and copy the link it shows."
        exit 1 ;;
esac

as_is=$(printf '%s' "$TEST_LINK" | grep -o 'backpack://t\.[A-Za-z0-9_-]*' | head -n 1)
as_is=${as_is#backpack://t.}
joined=${flat#*backpack://t.}
joined=${joined%%[!A-Za-z0-9_-]*}

token=
for candidate in "$as_is" "$joined"; do
    if valid_token "$candidate"; then token=$candidate; break; fi
done
if [ -z "$token" ]; then
    echo "$LOG The Connection Test link in TEST_LINK is damaged or cut short - copy all of it again from the Iran server."
    exit 1
fi

echo "$LOG Running the connection test from TEST_LINK. It can take several minutes; the Iran server must still have the test open."

# Only the link itself is handed over. BackPack's output is prefixed so that it can be told
# apart from the other programs in the shared log (a read loop, because the BusyBox sed of the
# Alpine image has no -u and would hold the lines back).
backpack link apply "backpack://t.$token" </dev/null 2>&1 | while IFS= read -r line || [ -n "$line" ]; do
    printf '%s %s\n' "$LOG" "$line"
done
rc=${PIPESTATUS[0]}

case "$rc" in
    0) echo "$LOG The test finished - the verdict is in the lines above. Remove TEST_LINK when you are done; the link only works while the test is open on the Iran server." ;;
    *) echo "$LOG The test did not complete (exit $rc). Is the Connection Test still open on the Iran server ('sudo backpack' -> 0) and is the link a fresh one? Start a new test there and use its new link." ;;
esac
exit "$rc"
