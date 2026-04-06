#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?age version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) A_ARCH="amd64" ;;
  arm64) A_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://github.com/FiloSottile/age/releases/download/v${VERSION}/age-v${VERSION}-linux-${A_ARCH}.tar.gz"
tar -xzf "age-v${VERSION}-linux-${A_ARCH}.tar.gz"
install -m 0755 "age/age" /usr/local/bin/age
install -m 0755 "age/age-keygen" /usr/local/bin/age-keygen
rm -rf age "age-v${VERSION}-linux-${A_ARCH}.tar.gz"
