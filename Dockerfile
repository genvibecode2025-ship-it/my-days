# Base image
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install desktop environment + VNC + noVNC + websockify + basics
RUN apt update -y && \
    apt install --no-install-recommends -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        novnc websockify \
        sudo xterm \
        dbus-x11 x11-utils x11-xserver-utils x11-apps \
        software-properties-common \
        vim net-tools curl wget git tzdata && \
    apt clean

# Add Firefox PPA
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt update -y && \
    apt install -y firefox && \
    apt clean

# Touch .Xauthority so no errors
RUN touch /root/.Xauthority

# Expose desktop & web ports
EXPOSE 5901
EXPOSE 6080
# Important: Render / Railway will map $PORT to external HTTP port

# Start VNC + noVNC via websockify on $PORT
CMD bash -c "\
    # Start VNC server :1 on port 5901
    mkdir -p /root/.vnc && \
    vncserver :1 -geometry 1280x800 -SecurityTypes None --I-KNOW-THIS-IS-INSECURE && \
    \
    # Generate self-signed cert for WebSockets
    openssl req -new -subj \"/C=US/ST=Denial/L=Nowhere/O=Dis/CN=localhost\" -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem && \
    \
    # Start websockify/noVNC on Render PORT
    websockify --web=/usr/share/novnc/ --cert=/tmp/self.pem \$PORT localhost:5901 & \
    \
    # Keep container running
    tail -f /dev/null"
