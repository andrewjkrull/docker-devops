# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.12-slim-trixie
ARG RUNTIME_IMAGE=debian:trixie-slim

############################
# stage: docker-cli-source
############################
FROM ${RUNTIME_IMAGE} AS docker-cli-source

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

############################
# stage: tools-builder
############################
FROM ${PYTHON_IMAGE} AS tools-builder

ARG DEBIAN_FRONTEND=noninteractive

ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION
ARG TERRAFORM_VERSION
ARG OPENTOFU_VERSION
ARG PACKER_VERSION
ARG VAULT_VERSION
ARG KUBECTL_VERSION
ARG HELM_VERSION
ARG KUSTOMIZE_VERSION
ARG TRIVY_VERSION
ARG GRYPE_VERSION
ARG YQ_VERSION
ARG SOPS_VERSION
ARG AGE_VERSION
ARG GITLEAKS_VERSION
ARG SYFT_VERSION
ARG K3D_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    make \
    openssh-client \
    tar \
    unzip \
    wget \
    xz-utils \
    zip \
    file \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    "ansible==${ANSIBLE_VERSION}" \
    "ansible-lint==${ANSIBLE_LINT_VERSION}"

WORKDIR /tmp/build
COPY scripts/ /tmp/build/scripts/
RUN chmod +x /tmp/build/scripts/*.sh

RUN /tmp/build/scripts/install-terraform.sh "${TERRAFORM_VERSION}" && \
    /tmp/build/scripts/install-opentofu.sh "${OPENTOFU_VERSION}" && \
    /tmp/build/scripts/install-packer.sh "${PACKER_VERSION}" && \
    /tmp/build/scripts/install-vault.sh "${VAULT_VERSION}" && \
    /tmp/build/scripts/install-kubectl.sh "${KUBECTL_VERSION}" && \
    /tmp/build/scripts/install-helm.sh "${HELM_VERSION}" && \
    /tmp/build/scripts/install-kustomize.sh "${KUSTOMIZE_VERSION}" && \
    /tmp/build/scripts/install-trivy.sh "${TRIVY_VERSION}" && \
    /tmp/build/scripts/install-grype.sh "${GRYPE_VERSION}" && \
    /tmp/build/scripts/install-yq.sh "${YQ_VERSION}" && \
    /tmp/build/scripts/install-sops.sh "${SOPS_VERSION}" && \
    /tmp/build/scripts/install-age.sh "${AGE_VERSION}" && \
    /tmp/build/scripts/install-gitleaks.sh "${GITLEAKS_VERSION}" && \
    /tmp/build/scripts/install-syft.sh "${SYFT_VERSION}" && \
    /tmp/build/scripts/install-k3d.sh "${K3D_VERSION}"

############################
# stage: runtime
############################
FROM ${RUNTIME_IMAGE} AS runtime

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=devops
ARG UID=1000
ARG GID=1000

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin \
    ANSIBLE_CONFIG=/workspace/ansible.cfg

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    make \
    openssh-client \
    tar \
    unzip \
    wget \
    xz-utils \
    zip \
    vim-nox \
    tini \
    openssl \
    iproute2 \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Python runtime for ansible
COPY --from=tools-builder /usr/local /usr/local

# Terraform bianry from builder
COPY --from=tools-builder /usr/bin/terraform /usr/bin/terraform
COPY --from=tools-builder /usr/bin/vault /usr/bin/vault

# Docker client tooling from official Docker repo stage
COPY --from=docker-cli-source /usr/bin/docker /usr/bin/docker
COPY --from=docker-cli-source /usr/libexec/docker/cli-plugins /usr/libexec/docker/cli-plugins

# Create non-root user for local usage
RUN groupadd --gid "${GID}" "${USERNAME}" && \
    useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}" && \
    mkdir -p /workspace && \
    chown -R "${USERNAME}:${USERNAME}" /workspace /home/"${USERNAME}"

WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash"]

############################
# stage: smoke-test
############################
FROM runtime AS smoke-test

RUN bash -lc '\
  python3 --version && \
  ansible --version && \
  ansible-lint --version && \
  terraform version && \
  tofu version && \
  packer version && \
  vault version && \
  kubectl version --client && \
  helm version && \
  kustomize version && \
  trivy version && \
  grype version && \
  syft version && \
  docker buildx version \
'
