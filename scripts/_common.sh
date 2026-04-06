#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[INFO] $*"
}

err() {
  echo "[ERROR] $*" >&2
}

require_version() {
  local version="${1:-}"
  local name="${2:-tool}"

  if [[ -z "${version}" ]]; then
    err "${name} version required"
    exit 1
  fi
}

get_dpkg_arch() {
  dpkg --print-architecture
}

map_arch() {
  local input_arch="${1:?input arch required}"
  shift

  local pair key value
  for pair in "$@"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    if [[ "${input_arch}" == "${key}" ]]; then
      echo "${value}"
      return 0
    fi
  done

  err "Unsupported architecture: ${input_arch}"
  exit 1
}

download_file() {
  local url="${1:?url required}"
  local output="${2:?output file required}"

  log "Downloading ${url}"
  curl --fail --show-error --silent --location \
    --retry 5 \
    --retry-delay 2 \
    --retry-connrefused \
    --connect-timeout 20 \
    -o "${output}" "${url}"

  if [[ ! -s "${output}" ]]; then
    err "Downloaded file is empty: ${output}"
    exit 1
  fi
}

cleanup_apt() {
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
