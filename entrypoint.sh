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

# Set VNC password for root
mkdir -p /root/.vnc
echo "$ROOT_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Set VNC password for user
mkdir -p /home/$USER_NAME/.vnc
echo "$USER_PASSWORD" | vncpasswd -f > /home/$USER_NAME/.vnc/passwd
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

echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
