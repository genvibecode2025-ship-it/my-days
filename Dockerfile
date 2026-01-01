##################################
# 1) Base: Ubuntu Desktop + noVNC
##################################
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

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

##################################
# 2) Create normal user
##################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

##################################
# 3) Set VNC password
##################################
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd VNCpass123! /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

##################################
# 4) Xauthority
##################################
RUN touch /home/user/.Xauthority && chown user:user /home/user/.Xauthority

##################################
# 5) Caddy reverse proxy
##################################
RUN wget https://github.com/caddyserver/caddy/releases/latest/download/caddy_2_linux_amd64.tar.gz && \
    tar -xzf caddy_2_linux_amd64.tar.gz && mv caddy /usr/bin/caddy && chmod +x /usr/bin/caddy && \
    rm caddy_2_linux_amd64.tar.gz

##################################
# 6) Add login page
##################################
COPY index.html /usr/share/novnc/custom/index.html

##################################
# 7) Add Caddy config
##################################
COPY Caddyfile /etc/caddy/Caddyfile

##################################
# 8) Expose only one HTTPS port
##################################
EXPOSE 443

##################################
# 9) Entrypoint
##################################
CMD bash -c "\
    rm -f /tmp/.X?-lock /tmp/.X11-unix/X? && \
    sudo -u user vncserver :1 -geometry 1366x768 -SecurityTypes VncAuth && sleep 5 && \
    caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"
