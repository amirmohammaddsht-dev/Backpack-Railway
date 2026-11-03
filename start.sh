#!/bin/bash

MY_PANEL_PORT=${PANEL_PORT:-2053}
MY_SUB_PORT=${SUB_PORT:-2096}

mkdir -p /etc/x-ui/
cd /usr/local/x-ui/

# Default panel settings
./x-ui setting -username admin -password admin
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/' WHERE key = 'webBasePath';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_PANEL_PORT}' WHERE key = 'webPort';" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '${MY_SUB_PORT}' WHERE key = 'subPort';" 2>/dev/null || true

echo "Starting 3x-ui Panel..."
./x-ui &

cd /app/c-tunnel

if [ -z "$TUNNEL_LINK" ]; then
    echo "==========================================================="
    echo "Manual Mode Active: No TUNNEL_LINK variable found."
    echo "Open Railway Terminal to test and configure C-Tunnel."
    echo "==========================================================="
    tail -f /dev/null
else
    echo "==========================================================="
    echo "Auto Mode Active: Starting C-Tunnel Engine directly."
    echo "==========================================================="
    
    # Run the engine directly to bypass systemctl
    # We use a trick: run the apply-link command but override PATH to catch the systemctl call,
    # OR better yet, extract the engine args if possible. 
    # Since C-Tunnel's apply-link handles the decoding, we will create a fake 'systemctl' command
    # that just succeeds, allowing apply-link to finish its setup without crashing.
    
    mkdir -p /tmp/fake-bin
    cat << 'EOF' > /tmp/fake-bin/systemctl
#!/bin/sh
echo "Fake systemctl called with args: $@"
exit 0
EOF
    chmod +x /tmp/fake-bin/systemctl
    export PATH="/tmp/fake-bin:$PATH"

    # Now apply the link. It will think it installed the service successfully.
    ./c-tunnel apply-link "$TUNNEL_LINK"
    
    # The apply-link command exits after saving the service. 
    # We must now manually start the engine that apply-link configured.
    # C-Tunnel creates a config file in /etc/ctunnel/ or similar, but the exact engine binary 
    # is usually located in a sub-folder or requires specific args.
    # A cleaner approach for Docker is to just run the tunnel engine based on the extracted configs.
    
    echo "Starting background engine..."
    # Find the generated systemd service file to extract the ExecStart command
    SERVICE_FILE=$(find /etc/systemd/system -name "ctunnel-engine*.service" | head -n 1)
    
    if [ -f "$SERVICE_FILE" ]; then
        EXEC_CMD=$(grep '^ExecStart=' "$SERVICE_FILE" | sed 's/^ExecStart=//')
        echo "Running extracted command: $EXEC_CMD"
        eval "$EXEC_CMD"
    else
        echo "Failed to find generated service file. Container will sleep to allow debugging."
        tail -f /dev/null
    fi
fi
