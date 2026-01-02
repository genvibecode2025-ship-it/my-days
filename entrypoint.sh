#!/bin/bash
set -e

# Passwords
ROOT_PASSWORD=${ROOT_PASSWORD:-"secret"}
USER_PASSWORD=${USER_PASSWORD:-"secret"}
USER_NAME=${USER_NAME:-"user"}
PORT=${PORT:-10000}

echo "Setting up environment..."
echo "Render PORT is set to: $PORT"

# Set passwords
echo "root:$ROOT_PASSWORD" | chpasswd
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# Export PASSWORD for Code-Server (uses the ROOT_PASSWORD)
export PASSWORD=$ROOT_PASSWORD

# Ensure code-server dirs exist (avoids failures on fresh volumes)
mkdir -p /root/.local/share/code-server /root/.local/share/code-server/extensions

# Find vncpasswd command
VNCPASSWD="vncpasswd"
if ! command -v vncpasswd &> /dev/null; then
    echo "vncpasswd command not found in PATH, searching..."
    if [ -f /usr/bin/vncpasswd ]; then
        VNCPASSWD="/usr/bin/vncpasswd"
    elif [ -f /usr/bin/tigervncpasswd ]; then
        VNCPASSWD="/usr/bin/tigervncpasswd"
    else
        echo "WARNING: vncpasswd not found. VNC setup might fail."
    fi
fi
echo "Using vncpasswd command: $VNCPASSWD"

# Set VNC password for root
mkdir -p /root/.vnc
echo "$ROOT_PASSWORD" | $VNCPASSWD -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Set VNC password for user
mkdir -p /home/$USER_NAME/.vnc
echo "$USER_PASSWORD" | $VNCPASSWD -f > /home/$USER_NAME/.vnc/passwd
chmod 600 /home/$USER_NAME/.vnc/passwd
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.vnc

# Generate SSH Host Keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Generate self-signed certificate for noVNC if needed
if [ ! -f /etc/ssl/certs/novnc.pem ]; then
    openssl req -new -x509 -days 365 -nodes \
        -out /etc/ssl/certs/novnc.pem \
        -keyout /etc/ssl/certs/novnc.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"
    chmod 644 /etc/ssl/certs/novnc.pem
fi

# Generate Nginx Config from Template
export PORT
envsubst '$PORT' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Validating Nginx config..."
/usr/sbin/nginx -t -c /etc/nginx/nginx.conf

# Avoid leaking Render's PORT to code-server.
# Nginx is the only public entrypoint and already binds to $PORT.
unset PORT

# Ensure code-server doesn't keep a stale bind-addr in its config.
mkdir -p /root/.config/code-server
rm -f /root/.config/code-server/config.yaml

echo "Starting VNC server..."
/usr/bin/vncserver :1 -geometry 1920x1080 -depth 24 -localhost yes

echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
