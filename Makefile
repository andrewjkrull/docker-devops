# ---------------------------------------------------------------------------
# Makefile — devops-toolkit
#
# Targets:
#   Full image (local interactive):
#     make build          build devops-toolkit:full
#     make smoke          smoke-test the full image
#     make run            interactive shell (workspace + docker socket)
#
#   CI runner images:
#     make ci-k8s         build devops-toolkit:ci-k8s
#     make ci-security    build devops-toolkit:ci-security
#     make ci-iac         build devops-toolkit:ci-iac
#     make ci-ansible     build devops-toolkit:ci-ansible
#     make ci-all         build all three CI images
#     make ci-smoke-k8s   smoke-test ci-k8s
#     make ci-smoke-sec   smoke-test ci-security
#     make ci-smoke-iac   smoke-test ci-iac
#     make ci-smoke-ansible smoke-test ci-ansible
#     make ci-smoke-all   smoke-test all CI images
#
#   Housekeeping:
#     make versions       print all pinned versions
#     make clean          remove all built images
# ---------------------------------------------------------------------------

IMAGE_NAME ?= devops-toolkit
IMAGE_TAG  ?= full

include versions.env
export

# ---------------------------------------------------------------------------
# Build args — full image uses everything
# ---------------------------------------------------------------------------
FULL_BUILD_ARGS = \
  --build-arg ANSIBLE_CORE_VERSION=$(ANSIBLE_CORE_VERSION) \
  --build-arg ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION) \
  --build-arg ANSIBLE_NETADDR_VERSION=$(ANSIBLE_NETADDR_VERSION) \
  --build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
  --build-arg OPENTOFU_VERSION=$(OPENTOFU_VERSION) \
  --build-arg PACKER_VERSION=$(PACKER_VERSION) \
  --build-arg VAULT_VERSION=$(VAULT_VERSION) \
  --build-arg KUBECTL_VERSION=$(KUBECTL_VERSION) \
  --build-arg HELM_VERSION=$(HELM_VERSION) \
  --build-arg KUSTOMIZE_VERSION=$(KUSTOMIZE_VERSION) \
  --build-arg TRIVY_VERSION=$(TRIVY_VERSION) \
  --build-arg GRYPE_VERSION=$(GRYPE_VERSION) \
  --build-arg YQ_VERSION=$(YQ_VERSION) \
  --build-arg SOPS_VERSION=$(SOPS_VERSION) \
  --build-arg AGE_VERSION=$(AGE_VERSION) \
  --build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION) \
  --build-arg SYFT_VERSION=$(SYFT_VERSION) \
  --build-arg K3D_VERSION=$(K3D_VERSION) \
  --build-arg DOCKER_VERSION=$(DOCKER_VERSION) \
  --build-arg AWSCLI_VERSION=$(AWSCLI_VERSION) \
  --build-arg AZURECLI_VERSION=$(AZURECLI_VERSION)

K8S_BUILD_ARGS = \
  --build-arg KUBECTL_VERSION=$(KUBECTL_VERSION) \
  --build-arg HELM_VERSION=$(HELM_VERSION) \
  --build-arg KUSTOMIZE_VERSION=$(KUSTOMIZE_VERSION) \
  --build-arg YQ_VERSION=$(YQ_VERSION) \
  --build-arg SOPS_VERSION=$(SOPS_VERSION) \
  --build-arg AGE_VERSION=$(AGE_VERSION)

SECURITY_BUILD_ARGS = \
  --build-arg TRIVY_VERSION=$(TRIVY_VERSION) \
  --build-arg GRYPE_VERSION=$(GRYPE_VERSION) \
  --build-arg SYFT_VERSION=$(SYFT_VERSION) \
  --build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION)

IAC_BUILD_ARGS = \
  --build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
  --build-arg OPENTOFU_VERSION=$(OPENTOFU_VERSION) \
  --build-arg VAULT_VERSION=$(VAULT_VERSION) \
  --build-arg SOPS_VERSION=$(SOPS_VERSION) \
  --build-arg AGE_VERSION=$(AGE_VERSION) \
  --build-arg YQ_VERSION=$(YQ_VERSION) \
  --build-arg AWSCLI_VERSION=$(AWSCLI_VERSION) \
  --build-arg AZURECLI_VERSION=$(AZURECLI_VERSION)

ANSIBLE_BUILD_ARGS = \
  --build-arg ANSIBLE_CORE_VERSION=$(ANSIBLE_CORE_VERSION) \
  --build-arg ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION) \
  --build-arg ANSIBLE_NETADDR_VERSION=$(ANSIBLE_NETADDR_VERSION)

# ---------------------------------------------------------------------------
# Full image
# ---------------------------------------------------------------------------
.PHONY: build
build:
	docker build $(FULL_BUILD_ARGS) \
	  -f Dockerfile \
	  -t $(IMAGE_NAME):full \
	  -t $(IMAGE_NAME):latest \
	  .

.PHONY: smoke
smoke:
	docker build $(FULL_BUILD_ARGS) \
	  -f Dockerfile \
	  --target smoke-test \
	  -t $(IMAGE_NAME):smoke \
	  .

.PHONY: run
run:
	docker run --rm -it \
	  -v $(PWD):/workspace \
	  -v $(HOME)/.ssh:/home/devops/.ssh:ro \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  --user 1000:1000 \
	  $(IMAGE_NAME):full

# ---------------------------------------------------------------------------
# CI runner images
# ---------------------------------------------------------------------------
.PHONY: ci-k8s
ci-k8s:
	docker build $(K8S_BUILD_ARGS) \
	  -f ci/Dockerfile.k8s \
	  -t $(IMAGE_NAME):ci-k8s \
	  .

.PHONY: ci-security
ci-security:
	docker build $(SECURITY_BUILD_ARGS) \
	  -f ci/Dockerfile.security \
	  -t $(IMAGE_NAME):ci-security \
	  .

.PHONY: ci-iac
ci-iac:
	docker build $(IAC_BUILD_ARGS) \
	  -f ci/Dockerfile.iac \
	  -t $(IMAGE_NAME):ci-iac \
	  .

.PHONY: ci-ansible
ci-ansible:
	docker build $(ANSIBLE_BUILD_ARGS) \
	  -f ci/Dockerfile.ansible \
	  -t $(IMAGE_NAME):ci-ansible \
	  .

.PHONY: ci-all
ci-all: ci-k8s ci-security ci-iac ci-ansible
	@echo "All CI images built."

# ---------------------------------------------------------------------------
# CI smoke tests
# ---------------------------------------------------------------------------
.PHONY: ci-smoke-k8s
ci-smoke-k8s:
	docker build $(K8S_BUILD_ARGS) \
	  -f ci/Dockerfile.k8s \
	  --target smoke-test \
	  -t $(IMAGE_NAME):ci-k8s-smoke \
	  .

.PHONY: ci-smoke-sec
ci-smoke-sec:
	docker build $(SECURITY_BUILD_ARGS) \
	  -f ci/Dockerfile.security \
	  --target smoke-test \
	  -t $(IMAGE_NAME):ci-security-smoke \
	  .

.PHONY: ci-smoke-iac
ci-smoke-iac:
	docker build $(IAC_BUILD_ARGS) \
	  -f ci/Dockerfile.iac \
	  --target smoke-test \
	  -t $(IMAGE_NAME):ci-iac-smoke \
	  .

.PHONY: ci-smoke-ansible
ci-smoke-ansible:
	docker build $(ANSIBLE_BUILD_ARGS) \
	  -f ci/Dockerfile.ansible \
	  --target smoke-test \
	  -t $(IMAGE_NAME):ci-ansible-smoke \
	  .

.PHONY: ci-smoke-all
ci-smoke-all: ci-smoke-k8s ci-smoke-sec ci-smoke-iac ci-smoke-ansible
	@echo "All CI smoke tests passed."

# ---------------------------------------------------------------------------
# Housekeeping
# ---------------------------------------------------------------------------
.PHONY: versions
versions:
	@echo "--- Ansible ---"
	@echo "  ANSIBLE_CORE_VERSION=$(ANSIBLE_CORE_VERSION)"
	@echo "  ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION)"
	@echo "--- IaC ---"
	@echo "  TERRAFORM_VERSION=$(TERRAFORM_VERSION)"
	@echo "  OPENTOFU_VERSION=$(OPENTOFU_VERSION)"
	@echo "  PACKER_VERSION=$(PACKER_VERSION)"
	@echo "--- Secrets ---"
	@echo "  VAULT_VERSION=$(VAULT_VERSION)"
	@echo "  SOPS_VERSION=$(SOPS_VERSION)"
	@echo "  AGE_VERSION=$(AGE_VERSION)"
	@echo "--- Kubernetes ---"
	@echo "  KUBECTL_VERSION=$(KUBECTL_VERSION)"
	@echo "  HELM_VERSION=$(HELM_VERSION)"
	@echo "  KUSTOMIZE_VERSION=$(KUSTOMIZE_VERSION)"
	@echo "  K3D_VERSION=$(K3D_VERSION)"
	@echo "--- Security ---"
	@echo "  TRIVY_VERSION=$(TRIVY_VERSION)"
	@echo "  GRYPE_VERSION=$(GRYPE_VERSION)"
	@echo "  SYFT_VERSION=$(SYFT_VERSION)"
	@echo "  GITLEAKS_VERSION=$(GITLEAKS_VERSION)"
	@echo "--- Utilities ---"
	@echo "  YQ_VERSION=$(YQ_VERSION)"
	@echo "--- Cloud CLIs ---"
	@echo "  AWSCLI_VERSION=$(AWSCLI_VERSION)"
	@echo "  AZURECLI_VERSION=$(AZURECLI_VERSION)"
	@echo "--- Container tooling ---"
	@echo "  DOCKER_VERSION=$(DOCKER_VERSION)"

.PHONY: clean
clean:
	-docker rmi $(IMAGE_NAME):full $(IMAGE_NAME):latest 2>/dev/null || true
	-docker rmi $(IMAGE_NAME):ci-k8s $(IMAGE_NAME):ci-security $(IMAGE_NAME):ci-iac $(IMAGE_NAME):ci-ansible 2>/dev/null || true
	-docker rmi $(IMAGE_NAME):smoke $(IMAGE_NAME):ci-k8s-smoke $(IMAGE_NAME):ci-security-smoke $(IMAGE_NAME):ci-iac-smoke $(IMAGE_NAME):ci-ansible-smoke 2>/dev/null || true
