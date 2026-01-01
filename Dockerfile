# ---- Temel İmaj ----
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

###########################################
# 1) Gerekli Paketleri Kur
###########################################
RUN apt update -y && \
    apt install --no-install-recommends -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        x11vnc \
        novnc websockify \
        sudo xterm \
        dbus-x11 x11-utils x11-xserver-utils x11-apps \
        chromium-browser \
        wget curl vim net-tools git tzdata && \
    apt clean

###########################################
# 2) Kullanıcı Oluştur
###########################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

###########################################
# 3) VNC Parola Ayarla (x11vnc)
###########################################
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd VNCpass123! /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

###########################################
# 4) Xauthority
###########################################
RUN touch /home/user/.Xauthority && \
    chown user:user /home/user/.Xauthority

###########################################
# 5) Portlar
###########################################
# noVNC / HTTP port
EXPOSE 6080
# VNC display port
EXPOSE 5901

###########################################
# 6) Başlatma Komutu
###########################################
CMD bash -c "\
    mkdir -p /home/user/.vnc && \
    chown user:user /home/user/.vnc && \
    \
    # VNC server başlat
    sudo -u user vncserver :1 -geometry 1280x800 -SecurityTypes VncAuth && \
    \
    # Self-signed SSL sertifikası üret
    openssl req -new -subj \"/C=US/ST=State/L=City/O=Org/CN=localhost\" -x509 -days 365 -nodes \
        -out /tmp/self.pem -keyout /tmp/self.pem && \
    \
    # noVNC websockify (Render'in $PORT'u)
    websockify --web=/usr/share/novnc/ --cert=/tmp/self.pem \$PORT localhost:5901 & \
    \
    # Keep alive
    tail -f /dev/null"
