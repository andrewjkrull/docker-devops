#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?opentofu version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) TOFU_ARCH="amd64" ;;
  arm64) TOFU_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://github.com/opentofu/opentofu/releases/download/v${VERSION}/tofu_${VERSION}_linux_${TOFU_ARCH}.zip"
unzip -q "tofu_${VERSION}_linux_${TOFU_ARCH}.zip"
install -m 0755 tofu /usr/local/bin/tofu
rm -f tofu "tofu_${VERSION}_linux_${TOFU_ARCH}.zip"
