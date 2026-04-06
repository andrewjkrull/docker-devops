#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?grype version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) G_ARCH="amd64" ;;
  arm64) G_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://github.com/anchore/grype/releases/download/v${VERSION}/grype_${VERSION}_linux_${G_ARCH}.tar.gz"
tar -xzf "grype_${VERSION}_linux_${G_ARCH}.tar.gz"
install -m 0755 grype /usr/local/bin/grype
rm -f grype "grype_${VERSION}_linux_${G_ARCH}.tar.gz"
