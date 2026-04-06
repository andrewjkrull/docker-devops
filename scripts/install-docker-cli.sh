#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?docker version required}"

ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) D_ARCH="x86_64" ;;
  arm64) D_ARCH="aarch64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp

curl -fsSLO \
https://download.docker.com/linux/static/stable/${D_ARCH}/docker-${VERSION}.tgz

tar -xzf docker-${VERSION}.tgz

install -m 0755 docker/docker /usr/local/bin/docker

rm -rf docker docker-${VERSION}.tgz
