ARG BASE_IMAGE
FROM $BASE_IMAGE

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

# Setup Android SDK/JDK Environment Variables
ARG ANDROID_NDK
ARG ANDROID_JDK
ARG ANDROID_SDK_BUILDTOOLS
ARG ANDROID_SDK_SDKTOOLS
ARG ANDROID_SDK_PLATFORMTOOLS
ARG ANDROID_SDK_PLATFORM

ENV ANDROID_INSTALL_LOCATION ${UNITY_INSTALL_LOCATION}/Editor/Data/PlaybackEngines/AndroidPlayer
ENV ANDROID_HOME ${ANDROID_INSTALL_LOCATION}/SDK
ENV ANDROID_NDK_HOME ${ANDROID_INSTALL_LOCATION}/NDK

RUN if [ -d ${ANDROID_INSTALL_LOCATION} ] \
    ; then \
        echo "Android Install" \
    # JDK
        && if [ -n "${ANDROID_JDK}" ] \
        ; then \
            wget -q ${ANDROID_JDK} -O /tmp/jdk.zip \
            && unzip -q /tmp/jdk.zip -d ${ANDROID_INSTALL_LOCATION}/OpenJDK \
        ; else \
            apt-get update -qq \
            && add-apt-repository ppa:openjdk-r/ppa \
            && apt-get install -qq -y --no-install-recommends \
                openjdk-8-jdk \
        ; fi \
    # Android SDK Tool
        && wget -q ${ANDROID_SDK_SDKTOOLS} -O /tmp/sdk-tools-linux.zip \
        && unzip -q /tmp/sdk-tools-linux.zip -d ${ANDROID_HOME} \
    # Android SDK Platform Tools
        && wget -q ${ANDROID_SDK_PLATFORMTOOLS} -O /tmp/platform-tools.zip \
        && unzip -q /tmp/platform-tools.zip -d ${ANDROID_HOME} \
    # Android SDK Build Tools
        && wget -q ${ANDROID_SDK_BUILDTOOLS} -O /tmp/build-tools.zip \
        && unzip -q /tmp/build-tools.zip -d ${ANDROID_HOME}/build-tools \
        && mv ${ANDROID_HOME}/build-tools/android-9 ${ANDROID_HOME}/build-tools/28.0.3 \
    # Android SDK Platforms
        && wget -q ${ANDROID_SDK_PLATFORM} -O /tmp/platform.zip \
        && unzip -q /tmp/platform.zip -d ${ANDROID_HOME}/platforms \
        && mv ${ANDROID_HOME}/platforms/android-9 ${ANDROID_HOME}/platforms/android-28 \
    # Android NDK
        && wget -q ${ANDROID_NDK} -O /tmp/android-ndk.zip \
        && unzip -q /tmp/android-ndk.zip -d ${ANDROID_NDK_HOME} \
        && mv ${ANDROID_NDK_HOME}/*/* ${ANDROID_NDK_HOME} \
    # Accept license
        && yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses \
    # Set rights
        # && chmod -R 777 ${ANDROID_INSTALL_LOCATION} \
        # && ls -ahl ${ANDROID_HOME} \
    # Clean
        && apt-get autoremove \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /tmp/* \
        && rm -rf /var/tmp/* \
    ; fi