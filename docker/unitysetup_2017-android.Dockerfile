ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update -qq; \
    apt-get install -qq -y \
    locales \
    software-properties-common \
    unzip \
    && add-apt-repository ppa:openjdk-r/ppa \
    && add-apt-repository ppa:cwchien/gradle \
    && apt-get install -qq -y \
    gradle \
    openjdk-8-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Setup Android SDK/JDK Environment Variables
ENV ANDROID_SDK_VERSION ${ANDROID_SDK_VERSION:-28}
ENV ANDROID_SDK_TOOLS_VERSION ${ANDROID_SDK_TOOLS_VERSION:-28.0.3}
ENV ANDROID_SDK_COMPONENTS build-tools;$ANDROID_SDK_TOOLS_VERSION platform-tools platforms;android-$ANDROID_SDK_VERSION
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre/
ENV PATH ${PATH}:/usr/lib/jvm/java-8-openjdk-amd64/jre/bin
ENV ANDROID_HOME /opt/android-sdk-linux

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
ENV LANG en_US.UTF-8

# Install Android SDK Installer...
RUN cd /opt && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk.zip && \
    unzip -q android-sdk.zip -d android-sdk-linux && \
    rm -f android-sdk.zip && \
    ls -ahl android-sdk-linux

RUN chmod -R 755 .${ANDROID_HOME}/tools/*

# accept license
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses

# Install Android SDK
RUN ${ANDROID_HOME}/tools/bin/sdkmanager ${ANDROID_SDK_COMPONENTS} > /dev/null && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --list

RUN gradle -v

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
    # make a directory for the certificate Unity needs to run
    mkdir -p /root/.local/share/unity3d/Certificates/ && \
    # remove setup & temp files
    rm UnitySetup && \
    rm -rf /tmp/unity && \
    rm -rf /root/.local/share/Trash/* && \
    # android specific paths
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*
