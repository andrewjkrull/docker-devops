#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

VERSION="${1:-}"
require_version "${VERSION}" "vault"

export DEBIAN_FRONTEND=noninteractive

HASHICORP_KEYRING="/usr/share/keyrings/hashicorp-archive-keyring.gpg"
HASHICORP_REPO_FILE="/etc/apt/sources.list.d/hashicorp.list"

log "Installing Vault ${VERSION}"

ensure_hashicorp_repo() {
  if [[ -f "${HASHICORP_REPO_FILE}" && -f "${HASHICORP_KEYRING}" ]]; then
    log "HashiCorp apt repository already configured"
    return 0
  fi

  log "HashiCorp apt repository not found, configuring it now"

  apt-get update
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  install -m 0755 -d /usr/share/keyrings

  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o "${HASHICORP_KEYRING}"

  chmod a+r "${HASHICORP_KEYRING}"

  CODENAME="$(
    . /etc/os-release
    echo "${VERSION_CODENAME:-$(lsb_release -cs)}"
  )"

  echo "deb [arch=$(dpkg --print-architecture) signed-by=${HASHICORP_KEYRING}] https://apt.releases.hashicorp.com ${CODENAME} main" \
    > "${HASHICORP_REPO_FILE}"
}

ensure_hashicorp_repo

apt-get update
apt-get install -y --no-install-recommends "vault=${VERSION}-1"

vault version

cleanup_apt
