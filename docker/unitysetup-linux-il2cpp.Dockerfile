ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends \
        clang \
        llvm-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG DOWNLOAD_URL
ARG SHA1
ARG COMPONENTS=Linux-IL2CPP

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
