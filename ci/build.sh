#!/usr/bin/env sh

set -ex
source ci/set_registry_variables.sh

docker build -f ./docker/$DOCKERFILE_NAME.Dockerfile $IMAGE_LABELS --label build-date=`date -Iseconds` $IMAGE_ARGUMENTS --pull -t "$REGISTRY" ./docker/
docker push "$REGISTRY"

if [ "$CI_COMMIT_REF_NAME" = "master" ] && [ -n "$LATEST" ]; then
  echo "Marking $REGISTRY as latest image"
  docker tag "$REGISTRY" "$CI_REGISTRY_IMAGE:latest"
  docker push "$CI_REGISTRY_IMAGE:latest"
fi
