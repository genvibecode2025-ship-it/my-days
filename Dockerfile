###################################
# BASE: Ubuntu 22.04
###################################
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

###################################
# 1) Paketler: XFCE + VNC + noVNC
###################################
RUN apt update -y && \
    apt install --no-install-recommends -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        x11vnc \
        websockify \
        sudo xterm \
        dbus-x11 x11-utils x11-xserver-utils x11-apps \
        chromium-browser \
        wget curl vim net-tools git tzdata && \
    apt clean

###################################
# 2) Kullanıcı oluştur
###################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

###################################
# 3) VNC parola
###################################
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd VNCpass123! /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

###################################
# 4) .Xauthority
###################################
RUN touch /home/user/.Xauthority && chown user:user /home/user/.Xauthority

###################################
# 5) Parola ekranı
###################################
COPY index.html /usr/share/novnc/custom/index.html

###################################
# 6) Caddy için config
###################################
COPY Caddyfile /etc/caddy/Caddyfile

###################################
# 7) Port
###################################
EXPOSE 80
EXPOSE 443

###################################
# 8) Başlatma
###################################
CMD bash -c "\
    rm -f /tmp/.X?-lock /tmp/.X11-unix/X? && \
    sudo -u user vncserver :1 -geometry 1366x768 -SecurityTypes VncAuth && sleep 4 && \
    caddy run --config /etc/caddy/Caddyfile"
