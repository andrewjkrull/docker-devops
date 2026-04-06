#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?sops version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) S_ARCH="amd64" ;;
  arm64) S_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

curl -fsSL -o /usr/local/bin/sops \
  "https://github.com/getsops/sops/releases/download/v${VERSION}/sops-v${VERSION}.linux.${S_ARCH}"

chmod 0755 /usr/local/bin/sops
