IMAGE_NAME ?= devops-toolkit
IMAGE_TAG ?= latest

include versions.env

BUILD_ARGS = \
  --build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
  --build-arg ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION) \
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
  --build-arg DOCKER_VERSION=$(DOCKER_VERSION) \
  --build-arg SYFT_VERSION=$(SYFT_VERSION) \
  --build-arg K3D_VERSION=$(K3D_VERSION)

build:
	docker build $(BUILD_ARGS) -t $(IMAGE_NAME):$(IMAGE_TAG) .

smoke:
	docker build $(BUILD_ARGS) --target smoke-test -t $(IMAGE_NAME):smoke .

run:
	docker run --rm -it \
	  -v $(PWD):/workspace \
	  -v $$HOME/.ssh:/home/devops/.ssh:ro \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  --user 1000:1000 \
	  $(IMAGE_NAME):$(IMAGE_TAG)

versions:
	@echo "ANSIBLE_VERSION=$(ANSIBLE_VERSION)"
	@echo "ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION)"
	@echo "TERRAFORM_VERSION=$(TERRAFORM_VERSION)"
	@echo "OPENTOFU_VERSION=$(OPENTOFU_VERSION)"
	@echo "PACKER_VERSION=$(PACKER_VERSION)"
	@echo "VAULT_VERSION=$(VAULT_VERSION)"
	@echo "KUBECTL_VERSION=$(KUBECTL_VERSION)"
	@echo "HELM_VERSION=$(HELM_VERSION)"
	@echo "KUSTOMIZE_VERSION=$(KUSTOMIZE_VERSION)"
	@echo "TRIVY_VERSION=$(TRIVY_VERSION)"
	@echo "GRYPE_VERSION=$(GRYPE_VERSION)"
	@echo "YQ_VERSION=$(YQ_VERSION)"
	@echo "SOPS_VERSION=$(SOPS_VERSION)"
	@echo "AGE_VERSION=$(AGE_VERSION)"
	@echo "GITLEAKS_VERSION=$(GITLEAKS_VERSION)"
	@echo "SYFT_VERSION=$(SYFT_VERSION)"
	@echo "DOCKER_VERSION=$(DOCKER_VERSION)"
	@echo "K3D_VERSION=$(K3D_VERSION)"
