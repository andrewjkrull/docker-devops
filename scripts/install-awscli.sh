#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

VERSION="${1:-}"
require_version "${VERSION}" "awscli"

ARCH="$(dpkg --print-architecture)"
case "${ARCH}" in
  amd64) AWS_ARCH="x86_64" ;;
  arm64) AWS_ARCH="aarch64" ;;
  *) err "Unsupported architecture: ${ARCH}"; exit 1 ;;
esac

log "Installing AWS CLI ${VERSION} (${AWS_ARCH})"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

download_file \
  "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${VERSION}.zip" \
  "${TMPDIR}/awscli.zip"

unzip -q "${TMPDIR}/awscli.zip" -d "${TMPDIR}"
"${TMPDIR}/aws/install" --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin

aws --version
