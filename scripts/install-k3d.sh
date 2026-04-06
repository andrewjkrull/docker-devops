#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

VERSION="${1:-}"
require_version "${VERSION}" "k3d"

DPKG_ARCH="$(get_dpkg_arch)"
ARCH="$(map_arch "${DPKG_ARCH}" \
  "amd64=amd64" \
  "arm64=arm64" \
  "armhf=arm" \
  "armel=arm" \
  "i386=386")"

cd /tmp

FILE="k3d-linux-${ARCH}"
URL="https://github.com/k3d-io/k3d/releases/download/v${VERSION}/${FILE}"

log "Installing k3d ${VERSION} for dpkg arch=${DPKG_ARCH}, mapped arch=${ARCH}"

download_file "${URL}" "${FILE}"

chmod +x "${FILE}"
install -m 0755 "${FILE}" /usr/local/bin/k3d

rm -f "${FILE}"
