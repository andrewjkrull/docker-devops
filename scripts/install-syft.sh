#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

VERSION="${1:-}"
require_version "${VERSION}" "syft"

DPKG_ARCH="$(get_dpkg_arch)"
ARCH="$(map_arch "${DPKG_ARCH}" \
  "amd64=amd64" \
  "arm64=arm64" \
  "armhf=arm" \
  "armel=arm" \
  "i386=386")"

cd /tmp

FILE="syft_${VERSION}_linux_${ARCH}.tar.gz"
URL="https://github.com/anchore/syft/releases/download/v${VERSION}/${FILE}"

log "Installing Syft ${VERSION} for dpkg arch=${DPKG_ARCH}, mapped arch=${ARCH}"

download_file "${URL}" "${FILE}"

tar -xzf "${FILE}"

install -m 0755 syft /usr/local/bin/syft

rm -f syft "${FILE}"
