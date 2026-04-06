#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?helm version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) H_ARCH="amd64" ;;
  arm64) H_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://get.helm.sh/helm-v${VERSION}-linux-${H_ARCH}.tar.gz"
tar -xzf "helm-v${VERSION}-linux-${H_ARCH}.tar.gz"
install -m 0755 "linux-${H_ARCH}/helm" /usr/local/bin/helm
rm -rf "helm-v${VERSION}-linux-${H_ARCH}.tar.gz" "linux-${H_ARCH}"
