#!/usr/bin/env bash
set -euo pipefail
source /tmp/build/scripts/_common.sh

CORE_VERSION="${1:-}"
LINT_VERSION="${2:-}"
NETADDR_VERSION="${3:-}"

require_version "${CORE_VERSION}" "ansible-core"
require_version "${LINT_VERSION}" "ansible-lint"
require_version "${NETADDR_VERSION}" "netaddr"

log "Installing ansible-core ${CORE_VERSION}, ansible-lint ${LINT_VERSION}, netaddr ${NETADDR_VERSION}"

pip install --no-cache-dir \
    "ansible-core==${CORE_VERSION}" \
    "ansible-lint==${LINT_VERSION}" \
    "netaddr==${NETADDR_VERSION}"

python3 -c "import netaddr; print('netaddr', netaddr.__version__)"

ansible --version
ansible-lint --version
