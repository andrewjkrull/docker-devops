#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?packer version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) PKR_ARCH="amd64" ;;
  arm64) PKR_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_linux_${PKR_ARCH}.zip"
unzip -q "packer_${VERSION}_linux_${PKR_ARCH}.zip"
install -m 0755 packer /usr/local/bin/packer
rm -f packer "packer_${VERSION}_linux_${PKR_ARCH}.zip"
