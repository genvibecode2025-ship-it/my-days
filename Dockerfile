# Temel imaj
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

##########################################
# 1) Paketler
##########################################
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

##########################################
# 2) Kullanıcı
##########################################
RUN useradd -m -s /bin/bash user && \
    echo "user:StrongPass2026!" | chpasswd && \
    usermod -aG sudo user

##########################################
# 3) VNC Parolası
##########################################
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd VNCpass123! /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

##########################################
# 4) .Xauthority
##########################################
RUN touch /home/user/.Xauthority && \
    chown user:user /home/user/.Xauthority

##########################################
# 5) Parola Girişi
##########################################
COPY index.html /usr/share/novnc/custom/index.html

##########################################
# 6) Portlar
##########################################
EXPOSE 6080
EXPOSE 5901

##########################################
# 7) Başlatma
##########################################
CMD bash -c "\
    # Eski X11 socketlerini temizle
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 && \
    \
    # VNC serveri aç
    sudo -u user vncserver :1 -geometry 1366x768 -SecurityTypes VncAuth && \
    sleep 4 && \
    \
    # Self-signed SSL sertifikası
    openssl req -new -subj \"/C=US/ST=State/L=City/O=Org/CN=localhost\" \
        -x509 -days 365 -nodes \
        -out /tmp/self.pem -keyout /tmp/self.pem && \
    \
    # noVNC websockify
    websockify --web=/usr/share/novnc/custom --cert=/tmp/self.pem \$PORT localhost:5901"
