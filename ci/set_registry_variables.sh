#!/usr/bin/env sh

set -ex
if [ "$CI_COMMIT_REF_NAME" = "master" ]; then
  export REGISTRY=$CI_REGISTRY_IMAGE:$TAG
  export BASE_IMAGE=${BASE_IMAGE:-$CI_REGISTRY_IMAGE:$VERSION$BUILD}
else
  export REGISTRY=$CI_REGISTRY_IMAGE:$TAG-$CI_COMMIT_REF_SLUG
  export BASE_IMAGE=${BASE_IMAGE:-$CI_REGISTRY_IMAGE:$VERSION$BUILD-$CI_COMMIT_REF_SLUG}
fi

export IMAGE_LABELS=$(echo\
  --label vcs-url=$CI_PROJECT_URL \
  --label com.gitlab.ci.builder=$GITLAB_USER_EMAIL \
  --label com.gitlab.ci.pipeline=$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID \
  --label com.gitlab.ci.ref=$CI_BUILD_REF_NAME \
  --label com.gitlab.ci.build=$CI_PROJECT_URL/builds/$CI_BUILD_ID \
  --label com.gableroux.unity3d.version=$VERSION \
  --label com.gableroux.unity3d.build=$BUILD \
  --label com.gableroux.unity3d.tag=$TAG \
  --label com.gableroux.unity3d.download_url=$DOWNLOAD_URL \
  --label com.gableroux.unity3d.sha1=$SHA1 \
  --label com.gableroux.unity3d.release_notes=$RELEASE_NOTES \
  --label com.gableroux.unity3d.release_url=$RELEASE_URL
)

if [ "$COMPONENTS" = "Android" ]; then
    if [[ -z "${ANDROID_NDK_VERSION}" ]] \
    || [[ -z "${ANDROID_CMD_LINE_TOOLS_VERSION}" ]] \
    || [[ -z "${ANDROID_BUILD_TOOLS_VERSION}" ]] \
    || [[ -z "${ANDROID_PLATFORM_VERSION}" ]]; then
      echo "ANDROID_NDK_VERSION, ANDROID_CMD_LINE_TOOLS_VERSION, ANDROID_BUILD_TOOLS_VERSION or ANDROID_PLATFORM_VERSION environment variables are not set, please refer to instructions in the readme and add these to your environment variables."
      exit 1
    fi

    export IMAGE_ARGUMENTS=$(echo\
      --build-arg DOWNLOAD_URL=$DOWNLOAD_URL \
      --build-arg COMPONENTS=$COMPONENTS \
      --build-arg SHA1=$SHA1 \
      --build-arg BASE_IMAGE=$BASE_IMAGE \
      --build-arg ANDROID_NDK_VERSION=$ANDROID_NDK_VERSION \
      --build-arg ANDROID_CMD_LINE_TOOLS_VERSION=$ANDROID_CMD_LINE_TOOLS_VERSION \
      --build-arg ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION \
      --build-arg ANDROID_PLATFORM_VERSION=$ANDROID_PLATFORM_VERSION
    )
else
    export IMAGE_ARGUMENTS=$(echo\
      --build-arg DOWNLOAD_URL=$DOWNLOAD_URL \
      --build-arg COMPONENTS=$COMPONENTS \
      --build-arg SHA1=$SHA1 \
      --build-arg BASE_IMAGE=$BASE_IMAGE
    )
fi
