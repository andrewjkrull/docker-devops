#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

VERSION="${1:-}"
require_version "${VERSION}" "azure-cli"

export DEBIAN_FRONTEND=noninteractive

log "Installing Azure CLI ${VERSION}"

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg

chmod a+r /etc/apt/keyrings/microsoft.gpg

CODENAME="$(
  . /etc/os-release
  echo "${VERSION_CODENAME:-$(lsb_release -cs)}"
)"

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli ${CODENAME} main" \
  > /etc/apt/sources.list.d/azure-cli.list

apt-get update
apt-get install -y --no-install-recommends "azure-cli=${VERSION}-1~${CODENAME}"

az version

cleanup_apt
