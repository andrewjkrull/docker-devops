#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "${VERSION}" ]]; then
  echo "terraform version required" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gpg \
  lsb-release

install -m 0755 -d /usr/share/keyrings

curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

chmod a+r /usr/share/keyrings/hashicorp-archive-keyring.gpg

CODENAME="$(
  . /etc/os-release
  echo "${VERSION_CODENAME:-$(lsb_release -cs)}"
)"

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y --no-install-recommends "terraform=${VERSION}-1"
apt-get clean
rm -rf /var/lib/apt/lists/*

terraform version
