# Ubuntu tabanlı imaj
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

##########################################
# 1) Temel Paketler
##########################################
RUN apt update -y && \
    apt install --no-install-recommends -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        novnc websockify \
        sudo xterm \
        dbus-x11 x11-utils x11-xserver-utils x11-apps \
        wget curl vim net-tools git tzdata && \
    apt clean

##########################################
# 2) Kullanıcı Oluşturma
##########################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

##########################################
# 3) VNC Parola Ayarı
##########################################
RUN mkdir -p /home/user/.vnc && \
    echo "VNCpass123!" | vncpasswd -f > /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

##########################################
# 4) Chromium Tarayıcı
##########################################
RUN apt update -y && \
    apt install -y chromium-browser && \
    apt clean

##########################################
# 5) .Xauthority
##########################################
RUN touch /home/user/.Xauthority && \
    chown user:user /home/user/.Xauthority

##########################################
# 6) Portlar
##########################################
# VNC port (iç bağlantı için)
EXPOSE 5901
# noVNC / web port
EXPOSE 6080

##########################################
# 7) Startup Script
##########################################
CMD bash -c "\
    mkdir -p /home/user/.vnc && \
    chown user:user /home/user/.vnc && \
    \
    # VNC sunucusunu başlat
    sudo -u user vncserver :1 -geometry 1280x800 -SecurityTypes VncAuth && \
    \
    # Self-signed sertifika
    openssl req -new -subj \"/C=US/ST=State/L=City/O=Org/CN=localhost\" -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem && \
    \
    # noVNC websockify (Render $PORT ile)
    websockify --web=/usr/share/novnc/ --cert=/tmp/self.pem \$PORT localhost:5901 & \
    \
    tail -f /dev/null"
