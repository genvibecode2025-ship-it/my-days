# Base image
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

##########################################
# 1) Masaüstü + VNC + noVNC + Firefox
##########################################
RUN apt update -y && \
    apt install --no-install-recommends -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        novnc websockify \
        sudo xterm \
        dbus-x11 x11-utils x11-xserver-utils x11-apps \
        vim net-tools curl wget git tzdata && \
    apt clean

# Firefox (Ubuntu resmi deposundan)
RUN apt update -y && apt install -y firefox && apt clean

##########################################
# 2) Root parolası
##########################################
RUN echo "root:RootPass123!" | chpasswd

##########################################
# 3) Xauthority
##########################################
RUN touch /root/.Xauthority

##########################################
# 4) Portlar
##########################################
# VNC port
EXPOSE 5901
# noVNC/websockify (Render bu PORT'u $PORT olarak ayarlar)
EXPOSE 6080

##########################################
# 5) Start komutu
##########################################
CMD bash -c "\
    mkdir -p /root/.vnc && \
    # VNC server aç
    vncserver :1 -geometry 1280x800 -SecurityTypes None --I-KNOW-THIS-IS-INSECURE && \
    \
    # Self-signed sertifika oluştur
    openssl req -new -subj \"/C=US/ST=Denial/L=Nowhere/O=Dis/CN=localhost\" -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem && \
    \
    # noVNC / websockify
    websockify --web=/usr/share/novnc/ --cert=/tmp/self.pem \$PORT localhost:5901 & \
    \
    # keep alive
    tail -f /dev/null"
