#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?kubectl version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) K_ARCH="amd64" ;;
  arm64) K_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

curl -fsSL -o /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/v${VERSION}/bin/linux/${K_ARCH}/kubectl"

chmod 0755 /usr/local/bin/kubectl
