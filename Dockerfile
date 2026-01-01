##############################################
# 1) CADDY BASE IMAGES
##############################################
FROM caddy:2.10.2-builder AS builder

# Dummy config so build doesn't fail
RUN xcaddy build \
    --with github.com/caddyserver/transform-encoder

##############################################
# 2) MAIN IMAGE
##############################################
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

##############################################
# A) Gerekli Paketler
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
# B) Kullanıcı
##############################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

##############################################
# C) VNC Parola
##############################################
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd VNCpass123! /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

##############################################
# D) .Xauthority
##############################################
RUN touch /home/user/.Xauthority && chown user:user /home/user/.Xauthority

##############################################
# E) Copy Login Page
##############################################
COPY index.html /usr/share/novnc/custom/index.html

##############################################
# F) Install Caddy
##############################################
COPY --from=builder /srv/caddy/caddy /usr/bin/caddy
RUN chmod +x /usr/bin/caddy

##############################################
# G) Copy Caddy Config
##############################################
COPY Caddyfile /etc/caddy/Caddyfile

##############################################
# H) Ports
##############################################
EXPOSE 80
EXPOSE 443

##############################################
# I) Start Script
##############################################
CMD bash -c "\
    rm -f /tmp/.X?-lock /tmp/.X11-unix/X? && \
    sudo -u user vncserver :1 -geometry 1366x768 -SecurityTypes VncAuth && sleep 4 && \
    caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"
