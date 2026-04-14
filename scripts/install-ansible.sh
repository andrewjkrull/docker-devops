#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

CORE_VERSION="${1:-}"
LINT_VERSION="${2:-}"

require_version "${CORE_VERSION}" "ansible-core"
require_version "${LINT_VERSION}" "ansible-lint"

log "Installing ansible-core ${CORE_VERSION} and ansible-lint ${LINT_VERSION}"

pip install --no-cache-dir \
    "ansible-core==${CORE_VERSION}" \
    "ansible-lint==${LINT_VERSION}"

ansible --version
ansible-lint --version
