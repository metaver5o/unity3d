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
    rm -rf /root/.local/share/Trash/* && \
    rm -rf /opt/Unity/Editor/Data/PlaybackEngines/AndroidPlayer/Tools/OpenJDK # Deleting OpenJDK, we're installing it elsewhere

###################
## ANDROID SETUP ##
###################
# Android SDK versions
ARG ANDROID_NDK_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION=29.0.3
ARG ANDROID_PLATFORM_VERSION=29

# Setup Android SDK/JDK Environment Variables
ENV ANDROID_INSTALL_LOCATION ${UNITY_INSTALL_LOCATION}/Editor/Data/PlaybackEngines/AndroidPlayer
ENV ANDROID_SDK_ROOT ${ANDROID_INSTALL_LOCATION}/SDK
ENV ANDROID_HOME ${ANDROID_SDK_ROOT}
ENV ANDROID_NDK_HOME ${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}
ENV PATH=${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

#Setup Java
# install openJDK 8
RUN apt-get update -qq \
    && add-apt-repository ppa:openjdk-r/ppa \
    && apt-get install -qq -y --no-install-recommends \
        openjdk-8-jdk

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:${PATH}

# Download Android SDK commandline tools
RUN export JAVA_HOME \
    && mkdir -p ${ANDROID_SDK_ROOT} \
    && chown -R 777 ${ANDROID_INSTALL_LOCATION} \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk.zip \
    && unzip -q android-sdk.zip -d ${ANDROID_SDK_ROOT} \
    && rm -f android-sdk.zip \
    && ls -ahl ${ANDROID_SDK_ROOT} \

# Install platform tools and NDK
    && yes | sdkmanager \
        "platform-tools" \
        "ndk;${ANDROID_NDK_VERSION}" \
        > /dev/null \

# Install specified build tools
    && yes | sdkmanager \
        "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
        > /dev/null \

# Install specified platform
    && yes | sdkmanager \
        "platforms;android-${ANDROID_PLATFORM_VERSION}" \
        > /dev/null \

# Accept licenses
    && yes | sdkmanager --licenses \

# Clean
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*