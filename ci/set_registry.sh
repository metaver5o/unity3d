#!/usr/bin/env sh

set -ex
if [ "$CI_COMMIT_REF_NAME" = "master" ]; then
  export REGISTRY=$CI_REGISTRY_IMAGE:$VERSION$BUILD
else
  export REGISTRY=$CI_REGISTRY_IMAGE:$VERSION$BUILD-$CI_COMMIT_REF_SLUG
fi
