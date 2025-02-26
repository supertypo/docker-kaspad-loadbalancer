#!/bin/sh

REPO_URL_MAIN="https://github.com/supertypop/docker-kaspad-loadbalancer"
DOCKER_REPO="supertypo/kaspad-loadbalancer"
ARCHES="linux/amd64 linux/arm64"

BUILD_DIR="$(dirname $0)"
PUSH=$1
VERSIONS=$2
TAG=${3:-master}
REPO_URL=${4:-$REPO_URL_MAIN}
REPO_DIR="$BUILD_DIR/work/$(echo $REPO_URL | sed -E 's/[^a-zA-Z0-9]+/_/g')"

if [ -z "$PUSH" ] || [ -z "$VERSIONS" ]; then
  echo "Usage: $0 push|nopush \"multiple versions\" [tag] [git-repo]"
  exit 1
fi

set -e

tag=$(git log -n1 --format="%cs.%h")

docker=docker
id -nG $USER | grep -qw docker || docker="sudo $docker"

plain_build() {
  echo
  echo "===================================================="
  echo " Running current arch build"
  echo "===================================================="

  $docker build --pull --tag $DOCKER_REPO:$tag "$BUILD_DIR"

  for version in $VERSIONS; do
    $docker tag $DOCKER_REPO:$tag $DOCKER_REPO:$version
    echo Tagged $DOCKER_REPO:$version
  done

  if [ "$PUSH" = "push" ]; then
    $docker push $DOCKER_REPO:$tag
    for version in $VERSIONS; do
      $docker push $DOCKER_REPO:$version
    done
  fi
  echo "===================================================="
  echo " Completed current arch build"
  echo "===================================================="
}

multi_arch_build() {
  echo
  echo "===================================================="
  echo " Running multi arch build"
  echo "===================================================="
  dockerRepoArgs=

  if [ "$PUSH" = "push" ]; then
    dockerRepoArgs="$dockerRepoArgs --push"
  fi

  for version in $VERSIONS; do
    dockerRepoArgs="$dockerRepoArgs --tag $DOCKER_REPO:$version"
  done

  $docker buildx build --pull --platform=$(echo $ARCHES | sed 's/ /,/g') $dockerRepoArgs \
    --tag $DOCKER_REPO:$tag "$BUILD_DIR"
  echo "===================================================="
  echo " Completed multi arch build"
  echo "===================================================="
}

if [ "$PUSH" = "push" ]; then
  echo
  echo "===================================================="
  echo " Setup multi arch build ($ARCHES)"
  echo "===================================================="
  if $docker buildx create --name=mybuilder --append --node=mybuilder0 --platform=$(echo $ARCHES | sed 's/ /,/g') --bootstrap --use 1>/dev/null 2>&1; then
    echo "SUCCESS - doing multi arch build"
    multi_arch_build
  else
    echo "FAILED - building on current arch"
    plain_build
  fi
else
  plain_build
fi
