#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

VERSION="${1:-}"
require_version "${VERSION}" "kustomize"

DPKG_ARCH="$(get_dpkg_arch)"
ARCH="$(map_arch "${DPKG_ARCH}" \
  "amd64=amd64" \
  "arm64=arm64" \
  "armhf=arm" \
  "armel=arm" \
  "i386=386")"

cd /tmp

FILE="kustomize_v${VERSION}_linux_${ARCH}.tar.gz"
URL="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${VERSION}/${FILE}"

log "Installing Kustomize ${VERSION} for dpkg arch=${DPKG_ARCH}, mapped arch=${ARCH}"
download_file "${URL}" "${FILE}"

tar -xzf "${FILE}"
install -m 0755 kustomize /usr/local/bin/kustomize

rm -f kustomize "${FILE}"
