#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?trivy version required}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64) T_ARCH="64bit" ;;
  arm64) T_ARCH="ARM64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

cd /tmp
curl -fsSLO "https://github.com/aquasecurity/trivy/releases/download/v${VERSION}/trivy_${VERSION}_Linux-${T_ARCH}.tar.gz"
tar -xzf "trivy_${VERSION}_Linux-${T_ARCH}.tar.gz"
install -m 0755 trivy /usr/local/bin/trivy
rm -f trivy "trivy_${VERSION}_Linux-${T_ARCH}.tar.gz" LICENSE README.md contrib/*.tpl 2>/dev/null || true
rm -rf contrib
