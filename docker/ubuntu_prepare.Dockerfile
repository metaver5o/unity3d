FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ARG DOWNLOAD_URL
ARG SHA1

RUN echo "America/New_York" > /etc/timezone && \
    apt-get update -qq \
    && apt-get install -qq -y \
        debconf \
        ffmpeg \
        freeglut3-dev \
        gconf-service \
        git \
        lib32gcc1 \
        lib32stdc++6 \
        libarchive13 \
        libasound2 \
        libc6 \
        libc6-i386 \
        libcairo2 \
        libcap2 \
        libcups2 \
        libcurl3 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libfreetype6 \
        libgcc1 \
        libgconf-2-4 \
        libgdk-pixbuf2.0-0 \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libglu1-mesa \
        libglu1-mesa-dev \
        libgtk2.0-0 \
        libgtk3.0 \
        libnotify4 \
        libnspr4 \
        libnss3 \
        libpango1.0-0 \
        libpq5 \
        libsoup2.4-1 \
        libstdc++6 \
        libunwind-dev \
        libx11-6 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        locales \
        lsb-release \
        mesa-common-dev \
        npm \
        openssh-server \
        pulseaudio \
        wget \
        xdg-utils \
        xvfb \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

# To avoid annoying "perl: warning: Setting locale failed." errors,
# do not allow the client to pass custom locals, see:
# http://stackoverflow.com/a/2510548/15677
RUN sed -i 's/^AcceptEnv LANG LC_\*$//g' /etc/ssh/sshd_config

RUN wget -nv ${DOWNLOAD_URL} -O UnitySetup && \
    # compare sha1 if given
    if [ -n "${SHA1}" -a "${SHA1}" != "" ]; then \
        echo "${SHA1}  UnitySetup" | sha1sum --check -; \
    else \
        echo "no sha1 given, skipping checksum"; \
    fi && \
    # make executable
    chmod +x UnitySetup && \
    # agree with license
    echo y | \
    # install unity with required components
    xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' \
    ./UnitySetup \
        --unattended \
        --install-location=/opt/Unity \
        --verbose \
        --download-location=/tmp/unity \
        --components=Unity && \
    # remove setup & temp files
    rm UnitySetup && \
    rm -rf /tmp/unity && \
    rm -rf /root/.local/share/Trash/*

RUN mkdir -p /root/.local/share/unity3d/Certificates/ && \
    mkdir -p /root/.local/share/unity3d/Unity/ && \
    /opt/Unity/Editor/Unity -batchmode -quit -nographics -createManualActivationFile -logfile /dev/stdout || :

ADD conf/CACerts.pem /root/.local/share/unity3d/Certificates/
ADD conf/asound.conf /etc/
