# syntax=docker/dockerfile:1

# ------------------------------------------------------------------------------
# Base Image: Ubuntu 22.04 LTS
# ------------------------------------------------------------------------------
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    ROOT_PASSWORD=secret \
    USER_PASSWORD=secret \
    USER_NAME=user \
    UID=1000 \
    GID=1000

# ------------------------------------------------------------------------------
# 1. System Update & Basic Tools (SSH Added)
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    sudo \
    vim \
    nano \
    unzip \
    htop \
    net-tools \
    iputils-ping \
    software-properties-common \
    locales \
    supervisor \
    openssl \
    ca-certificates \
    zsh \
    python3 \
    python3-pip \
    build-essential \
    gnupg2 \
    fonts-liberation \
    xdg-utils \
    openssh-server \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ------------------------------------------------------------------------------
# 2. Desktop Environment (XFCE4) & VNC
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Fix noVNC index
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html || true

# ------------------------------------------------------------------------------
# 3. Google Chrome
# ------------------------------------------------------------------------------
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google.gpg \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Wrapper for root chrome safety
RUN mv /usr/bin/google-chrome /usr/bin/google-chrome-orig && \
    echo '#!/bin/bash\nif [ "$EUID" -eq 0 ]; then\n  /usr/bin/google-chrome-orig --no-sandbox --disable-dev-shm-usage "$@"\nelse\n  /usr/bin/google-chrome-orig "$@"\nfi' > /usr/bin/google-chrome && \
    chmod +x /usr/bin/google-chrome && \
    ln -s /usr/bin/google-chrome /usr/bin/chrome

# ------------------------------------------------------------------------------
# 4. Code-Server
# ------------------------------------------------------------------------------
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ------------------------------------------------------------------------------
# 5. User Setup (Root + Normal User)
# ------------------------------------------------------------------------------
# Setup Root Oh-My-Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN chsh -s /bin/zsh root

# Create Normal User
RUN groupadd -g $GID $USER_NAME && \
    useradd -m -u $UID -g $GID -s /bin/zsh $USER_NAME && \
    usermod -aG sudo $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME && \
    chmod 0440 /etc/sudoers.d/$USER_NAME

# Setup Normal User Oh-My-Zsh
USER $USER_NAME
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
USER root

# ------------------------------------------------------------------------------
# 6. Configuration & Startup
# ------------------------------------------------------------------------------

# VNC Config for Root
RUN mkdir -p /root/.vnc && \
    echo "#!/bin/bash\nxrdb \$HOME/.Xresources\nstartxfce4 &" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# VNC Config for Normal User (Optional, if they use VNC)
RUN mkdir -p /home/$USER_NAME/.vnc && \
    echo "#!/bin/bash\nxrdb \$HOME/.Xresources\nstartxfce4 &" > /home/$USER_NAME/.vnc/xstartup && \
    chmod +x /home/$USER_NAME/.vnc/xstartup && \
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.vnc

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ------------------------------------------------------------------------------
# 7. Expose Ports & Run
# ------------------------------------------------------------------------------
# 22: SSH (Terminal access)
# 5901: VNC
# 6080: noVNC
# 8080: Code-Server
EXPOSE 22 5901 6080 8080

VOLUME ["/root", "/home/user"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
