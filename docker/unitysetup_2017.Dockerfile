ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ARG DOWNLOAD_URL
ARG SHA1
ARG COMPONENTS=Unity,Windows,Windows-Mono,Mac,Mac-Mono,WebGL

RUN wget -nv ${DOWNLOAD_URL} -O UnitySetup && \
    # compare sha1 if given
    if [ -n "${SHA1}" -a "${SHA1}" != "" ]; then \
        echo "${SHA1}  UnitySetup" | sha1sum --check -; \
    else \
        echo "no sha1 given, skipping checksum"; \
    fi && \
    # make executable
    chmod +x UnitySetup && \
    # 2017 difference: must have /tmp/ and /opt/unity/ folders before installation
    mkdir -p /tmp/unity && \
    mkdir -p /opt/Unity && \
    # agree with license
    echo y | \
    # install unity with required components
    xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' \
        ./UnitySetup \
            --unattended \
            --install-location=/opt/Unity \
            --verbose \
            --download-location=/tmp/unity \
            --components=$COMPONENTS && \
    # remove setup & temp files
    rm UnitySetup && \
    rm -rf /tmp/unity && \
    rm -rf /root/.local/share/Trash/*
