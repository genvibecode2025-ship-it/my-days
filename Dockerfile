##############################################
# Base Image: Use official Caddy image
##############################################
FROM caddy:2 AS base

##############################################
# Switch to root (Caddy runs as root, ok)
##############################################
USER root

##############################################
# Install packages (XFCE, VNC, noVNC, etc.)
##############################################
RUN apt update -y && \
    apt install --no-install-recommends -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        x11vnc \
        websockify \
        sudo xterm \
        dbus-x11 x11-utils x11-xserver-utils x11-apps \
        chromium-browser \
        wget curl vim net-tools tzdata && \
    apt clean

##############################################
# Create normal user
##############################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

##############################################
# Set VNC password
##############################################
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd VNCpass123! /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

##############################################
# Touch .Xauthority
##############################################
RUN touch /home/user/.Xauthority && chown user:user /home/user/.Xauthority

##############################################
# Copy login page
##############################################
COPY index.html /usr/share/novnc/custom/index.html

##############################################
# Copy Caddy config
##############################################
COPY Caddyfile /etc/caddy/Caddyfile

##############################################
# Expose needed ports
##############################################
EXPOSE 80
EXPOSE 443

##############################################
# Start VNC + Caddy
##############################################
CMD bash -c "\
    rm -f /tmp/.X?-lock /tmp/.X11-unix/X? && \
    sudo -u user vncserver :1 -geometry 1366x768 -SecurityTypes VncAuth && sleep 5 && \
    caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"
