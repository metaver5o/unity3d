FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN echo "America/New_York" > /etc/timezone && \
    apt-get update -qq; \
    apt-get install -qq -y \
        debconf \
        ffmpeg \
        freeglut3-dev \
        gconf-service \
        git \
        lib32gcc1 \
        lib32stdc++6 \
        libasound2 \
        libc6 \
        libc6-i386 \
        libcairo2 \
        libcap2 \
        libcups2 \
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
        libgtk3.0\
        libnotify4 \
        libnspr4 \
        libnss3 \
        libpango1.0-0 \
        libpq5 \
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
        lsb-release \
        mesa-common-dev \
        npm \
        pulseaudio \
        wget \
        xdg-utils \
        xvfb \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG DOWNLOAD_URL
ARG SHA1

RUN wget -nv ${DOWNLOAD_URL} -O unity.deb && \
    # compare sha1 if given
    if [ -n "${SHA1}" -a "${SHA1}" != "" ]; then \
      echo "${SHA1}  unity.deb" | sha1sum --check -; \
    else \
      echo "no sha1 given, skipping checksum"; \
    fi && \
    # install unity
    dpkg -i unity.deb && \
    # remove setup & temp files
    rm unity.deb \
    rm -rf /tmp/unity && \
    rm -rf /root/.local/share/Trash/*

Add conf/CACerts.pem /root/.local/share/unity3d/Certificates/
Add conf/asound.conf /etc/
