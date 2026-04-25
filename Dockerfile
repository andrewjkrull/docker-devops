# syntax=docker/dockerfile:1.7
# ---------------------------------------------------------------------------
# Dockerfile — devops-toolkit:full  (local interactive use)
# Contains every tool.  For lean CI runner images see ci/Dockerfile.*
# ---------------------------------------------------------------------------

ARG PYTHON_IMAGE=python:3.12-slim-bookworm
ARG RUNTIME_IMAGE=debian:bookworm-slim

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

ARG ANSIBLE_CORE_VERSION
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
ARG AWSCLI_VERSION
ARG AZURECLI_VERSION

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
    file \
    openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build
COPY scripts/ /tmp/build/scripts/
RUN chmod +x /tmp/build/scripts/*.sh

# Ansible (ansible-core only — much smaller than the community mega-package)
RUN /tmp/build/scripts/install-ansible.sh "${ANSIBLE_CORE_VERSION}" "${ANSIBLE_LINT_VERSION}"

# Kubernetes tooling
RUN /tmp/build/scripts/install-kubectl.sh "${KUBECTL_VERSION}"
RUN /tmp/build/scripts/install-helm.sh "${HELM_VERSION}"
RUN /tmp/build/scripts/install-kustomize.sh "${KUSTOMIZE_VERSION}"
RUN /tmp/build/scripts/install-k3d.sh "${K3D_VERSION}"

# Infrastructure as Code
RUN /tmp/build/scripts/install-terraform.sh "${TERRAFORM_VERSION}"
RUN /tmp/build/scripts/install-opentofu.sh "${OPENTOFU_VERSION}"
RUN /tmp/build/scripts/install-packer.sh "${PACKER_VERSION}"

# Secrets
RUN /tmp/build/scripts/install-vault.sh "${VAULT_VERSION}"
RUN /tmp/build/scripts/install-sops.sh "${SOPS_VERSION}"
RUN /tmp/build/scripts/install-age.sh "${AGE_VERSION}"

# Security / supply-chain
RUN /tmp/build/scripts/install-trivy.sh "${TRIVY_VERSION}"
RUN /tmp/build/scripts/install-grype.sh "${GRYPE_VERSION}"
RUN /tmp/build/scripts/install-syft.sh "${SYFT_VERSION}"
RUN /tmp/build/scripts/install-gitleaks.sh "${GITLEAKS_VERSION}"

# Utilities
RUN /tmp/build/scripts/install-yq.sh "${YQ_VERSION}"

# Cloud CLIs
RUN /tmp/build/scripts/install-awscli.sh "${AWSCLI_VERSION}"
RUN /tmp/build/scripts/install-azurecli.sh "${AZURECLI_VERSION}"

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
    PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/files/bin \
    ANSIBLE_CONFIG=/workspace/ansible.cfg

# Runtime apt packages — only what tools actually need at runtime
# NOTE: wget intentionally excluded (curl covers all use cases)
#       iproute2/iputils-ping are interactive diagnostics, not pipeline deps
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
    openssl \
    tini \
    vim-nox \
    iproute2 \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Python runtime + all /usr/local/bin binaries from builder in one layer
COPY --from=tools-builder /usr/local /usr/local

# HashiCorp apt-installed binaries land in /usr/bin, not /usr/local/bin
COPY --from=tools-builder /usr/bin/terraform /usr/bin/terraform
COPY --from=tools-builder /usr/bin/vault     /usr/bin/vault

# Cloud CLIs
COPY --from=tools-builder /usr/bin/az  /usr/bin/az
COPY --from=tools-builder /opt/az      /opt/az

# Docker CLI from official Docker apt stage
COPY --from=docker-cli-source /usr/bin/docker               /usr/bin/docker
COPY --from=docker-cli-source /usr/libexec/docker/cli-plugins /usr/libexec/docker/cli-plugins

# Non-root user for local interactive use
RUN groupadd --gid "${GID}" "${USERNAME}" \
    && useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && mkdir -p /workspace \
    && chown -R "${USERNAME}:${USERNAME}" /workspace /home/"${USERNAME}"

# ---------------------------------------------------------------------------
# Bundled files
#
# files/custom-ca/  — additional root CAs trusted by the image (opt-in).
#                     Drop .crt files here for environments with internal CAs.
# files/bin/        — bundled into the image at /files/bin/, on PATH.
#                     Scripts here are callable by name.
# files/share/      — bundled into the image at /files/. Catch-all for
#                     templates, configs, static helper content.
#
# All three directories are empty by default so a vanilla `docker build`
# works without any configuration.
# ---------------------------------------------------------------------------
COPY files/custom-ca/ /usr/local/share/ca-certificates/custom-ca/
RUN update-ca-certificates

COPY files/bin/   /files/bin/
COPY files/share/ /files/
RUN chmod +x /files/bin/* 2>/dev/null || true

WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash"]

############################
# stage: smoke-test
############################
FROM runtime AS smoke-test

RUN bash -lc '\
  echo "--- Python / Ansible ---" && \
  python3 --version && \
  ansible --version && \
  ansible-lint --version && \
  echo "--- Kubernetes ---" && \
  kubectl version --client && \
  helm version && \
  kustomize version && \
  k3d version && \
  echo "--- IaC ---" && \
  terraform version && \
  tofu version && \
  packer version && \
  echo "--- Secrets ---" && \
  vault version && \
  sops --version && \
  age --version && \
  echo "--- Security ---" && \
  trivy version && \
  grype version && \
  syft version && \
  gitleaks version && \
  echo "--- Utilities ---" && \
  yq --version && \
  docker buildx version && \
  echo "--- Cloud CLIs ---" && \
  aws --version && \
  az version && \
  echo "--- All tools OK ---" \
'
