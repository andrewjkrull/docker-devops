#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?gitleaks version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) GL_ARCH="x64" ;;
  arm64) GL_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_${GL_ARCH}.tar.gz"
tar -xzf "gitleaks_${VERSION}_linux_${GL_ARCH}.tar.gz"
install -m 0755 gitleaks /usr/local/bin/gitleaks
rm -f gitleaks "gitleaks_${VERSION}_linux_${GL_ARCH}.tar.gz" LICENSE README.md
