#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?yq version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) Y_ARCH="amd64" ;;
  arm64) Y_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

curl -fsSL -o /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/v${VERSION}/yq_linux_${Y_ARCH}"

chmod 0755 /usr/local/bin/yq
