# DevOps Toolkit Container

A reproducible **DevOps toolbox container** designed for:

- Local infrastructure development
- GitOps / CI pipelines
- Homelab automation
- Infrastructure as Code workflows

This image packages a curated set of DevOps tooling for working with:

- Infrastructure provisioning
- Configuration management
- Kubernetes operations
- Container building
- Security scanning
- Supply-chain analysis

The goal is to provide a **single containerized control environment** that can be used locally or inside CI runners.

---

# Features

- Version-pinned tooling via `versions.env`
- Multi-stage Docker build for smaller image size
- Compatible with **Docker socket mount** for container builds
- Ready for **CI usage (Gitea / GitHub / GitLab)**
- Easy to extend by adding installer scripts

---

# Installed Tools

## Infrastructure as Code

| Tool | Purpose |
|-----|-----|
| Terraform | Infrastructure provisioning |
| OpenTofu | Open source Terraform alternative |
| Packer | Image building |
| Ansible | Configuration management |

---

## Kubernetes Tooling

| Tool | Purpose |
|-----|-----|
| kubectl | Kubernetes CLI |
| Helm | Kubernetes package manager |
| Kustomize | Kubernetes manifest customization |

---

## Container Tooling

| Tool | Purpose |
|-----|-----|
| Docker CLI | Container build/push |
| Docker Buildx | Multi-platform builds |
| Docker Compose | Compose workflow support |

---

## Security & Supply Chain

| Tool | Purpose |
|-----|-----|
| Trivy | Container vulnerability scanner |
| Grype | Vulnerability scanner |
| Syft | SBOM generation |
| Gitleaks | Secret detection |

---

## Secrets Management

| Tool | Purpose |
|-----|-----|
| SOPS | Secret encryption |
| age | Encryption backend for SOPS |

---

## Utilities

| Tool | Purpose |
|-----|-----|
| jq | JSON processing |
| yq | YAML processing |
| git | Source control |
| curl / wget | Network utilities |
| make | Build automation |
| ssh client | Remote access |

---

# Repository Layout
devops-toolkit/
│
├── Dockerfile
├── Makefile
├── versions.env
├── README.md
│
├── scripts/
│ ├── _common.sh
│ ├── install-terraform.sh
│ ├── install-opentofu.sh
│ ├── install-packer.sh
│ ├── install-kubectl.sh
│ ├── install-helm.sh
│ ├── install-kustomize.sh
│ ├── install-trivy.sh
│ ├── install-grype.sh
│ ├── install-syft.sh
│ ├── install-yq.sh
│ ├── install-sops.sh
│ ├── install-age.sh
│ └── install-gitleaks.sh
│
└── .gitea/workflows/

Each tool is installed through a dedicated script to make it easy to add or upgrade tools.

---

# Version Management

Tool versions are controlled via:

```
versions.env
```

Example:

```
TERRAFORM_VERSION=1.14.6
ANSIBLE_VERSION=13.0.1
TRIVY_VERSION=0.69.3
```


Updating a tool only requires changing the version in this file and rebuilding the image.

---

# Building the Image

Build using the provided Makefile.

```
make build
```

Or specify custom tags:

```
make build IMAGE_NAME=devops-toolkit IMAGE_TAG=latest
```


---

# Running the Container

Run an interactive shell with the workspace mounted.

```
make run
```

Equivalent manual command:

```

```


This allows the container to:

- access your project files
- use your SSH keys
- build containers using the host Docker daemon

---

# Running Terraform

```
terraform init
terraform plan
terraform apply
```

---

# Running Ansible

```
ansible-playbook playbook.yml
```

---

# Kubernetes Usage

```
kubectl get pods
helm list
kustomize build .
```

---

# Container Builds

Because the Docker CLI is included, you can build and push containers directly.

```
docker build -t myapp:latest .
docker push registry.example.com/myapp:latest
```

The container communicates with the **host Docker daemon** through:

```
/var/run/docker.sock
```

This avoids running Docker-in-Docker.

---

# Security Scanning Example

Generate an SBOM:

```
syft myimage:latest
```


Scan for vulnerabilities:

```
grype myimage:latest
trivy image myimage:latest
```

Example CI pipeline step:

```
docker build -t app:${GIT_SHA} .
syft app:${GIT_SHA} -o spdx-json > sbom.json
grype app:${GIT_SHA}
trivy image app:${GIT_SHA}
```

---

# Makefile Targets

| Command | Description |
|-------|--------|
| `make build` | Build the container |
| `make run` | Start interactive dev container |
| `make smoke` | Run tool validation build |
| `make clean` | Remove image |

---

# CI Usage Example (Gitea)

Example workflow:

```

```

steps:
  - uses: actions/checkout@v4

  - name: Terraform
    run: terraform version

  - name: Docker build
    run: docker build -t myapp:${GITHUB_SHA} .

---

# Extending the Toolkit

To add a new tool:

1. Create an install script

```
scripts/install-mytool.sh
```

2. Add version to versions.env

```
MYTOOL_VERSION=X.X.X
```

3. Add Dockerfile build argument

```
ARG MYTOOL_VERSION
```

4. Call installer in Dockerfile

```
RUN /tmp/build/scripts/install-mytool.sh "${MYTOOL_VERSION}"
```

5. Add new tool variables to Makefile

BUILD_ARGS

```
--build-arg MYTOOL_VERSION=$(MYTOOL_VERSION)
```

versions:

```
@echo "MYTOOL_VERSION=$(MYTOOL_VERSION)"
```

---

# Recommended Usage

This container works well as a **DevOps control node** for:

- Homelab automation
- GitOps workflows
- CI pipelines
- Infrastructure deployments

The same environment can be used:

- locally
- inside Gitea runners
- in CI pipelines
- inside ephemeral development containers

---

# Future Improvements

Possible additions:

- Cosign (container signing)
- Flux CLI
- ArgoCD CLI
- kubeconform
- tfsec
- hadolint
- Azure CLI
- AWS CLI

---

# License

MIT License
