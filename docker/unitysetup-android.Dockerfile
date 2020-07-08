ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends \
        software-properties-common \
        unzip \
        openssh-server \
        locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Temporary additional layers since base images won't be republished for now
RUN locale-gen en_US.UTF-8

# To avoid annoying "perl: warning: Setting locale failed." errors,
# do not allow the client to pass custom locals, see:
# http://stackoverflow.com/a/2510548/15677
RUN sed -i 's/^AcceptEnv LANG LC_\*$//g' /etc/ssh/sshd_config

ARG DOWNLOAD_URL
ARG SHA1
ARG COMPONENTS=Unity,Windows,Windows-Mono,Mac,Mac-Mono,WebGL
ENV UNITY_INSTALL_LOCATION /opt/Unity

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
        --install-location=$UNITY_INSTALL_LOCATION \
        --verbose \
        --download-location=/tmp/unity \
        --components=$COMPONENTS && \
    # make a directory for the certificate Unity needs to run
    mkdir -p /root/.local/share/unity3d/Certificates/ && \
    # remove setup & temp files
    rm UnitySetup && \
    rm -rf /tmp/unity && \
    rm -rf /root/.local/share/Trash/*


###################
## ANDROID SETUP ##
###################
# Setup Android SDK/JDK Environment Variables
ENV ANDROID_SDK_ROOT /opt/android/sdk
ENV ANDROID_NDK_HOME ${ANDROID_SDK_ROOT}/NDK
ENV PATH=${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

# Android SDK versions
ARG ANDROID_NDK_VERSION
ARG ANDROID_CMD_LINE_TOOLS_VERSION=6609375
ARG ANDROID_BUILD_TOOLS_VERSION=29.0.3
ARG ANDROID_PLATFORM_VERSION=29

# install openJDK 8
RUN apt-get update -qq \
    && add-apt-repository ppa:openjdk-r/ppa \
    && apt-get install -qq -y --no-install-recommends \
        openjdk-8-jdk

# Download Android SDK commandline tools
RUN mkdir -p ${ANDROID_SDK_ROOT} \
    && chown -R 755 ${ANDROID_SDK_ROOT} \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMD_LINE_TOOLS_VERSION}_latest.zip -O android-sdk.zip \
    && unzip -q android-sdk.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && ln -s ${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin/sdkmanager /usr/local/bin \
    && rm -f android-sdk.zip \
    && ls -ahl ${ANDROID_SDK_ROOT}

# Accept licenses & update existing packages
RUN yes | sdkmanager --licenses && yes | sdkmanager --update

# Install tools, platform tools and NDK
RUN sdkmanager \
    "tools" \
    "platform-tools" \
    "ndk;${ANDROID_NDK_VERSION}" \
    > /dev/null

# Install specified build tools
RUN sdkmanager \
    "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    > /dev/null

# Install specified platform
RUN sdkmanager \
    "platforms;android-${ANDROID_PLATFORM_VERSION}" \
    > /dev/null

# Clean
RUN apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*