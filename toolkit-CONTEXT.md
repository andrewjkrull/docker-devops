# DevOps Toolkit — AI Session Context

## What this repository is
A Docker image that provides a reproducible, version-pinned DevOps toolbox.
Every tool runs inside the container — nothing is installed on the host.
Used as the sole tool execution environment for local Kubernetes PoC work,
CI pipelines, and infrastructure automation.

## Repository structure

```
docker-devops/
├── Dockerfile          <- multi-stage build (tools-builder → runtime → smoke-test)
├── Makefile            <- build / smoke / run / versions targets
├── versions.env        <- all tool versions pinned here — single source of truth
├── README.md           <- full documentation
└── scripts/
    ├── _common.sh      <- shared helpers: log(), err(), download_file(), map_arch()
    ├── install-*.sh    <- one script per tool, takes version as $1
    └── ...
```

## Build system

Versions are controlled exclusively via `versions.env`. The Makefile reads this
file and passes every version as a `--build-arg` to `docker build`. To update
any tool: change the version in `versions.env` and run `make build`.

```bash
make build          # build devops-toolkit:latest
make smoke          # build to smoke-test stage — validates all tools present
make run            # interactive shell with workspace + docker socket mounted
make versions       # print all current versions
```

Image name and tag are overridable:
```bash
make build IMAGE_NAME=devops-toolkit IMAGE_TAG=1.2.3
```

## Dockerfile stages

1. **docker-cli-source** — installs Docker CE CLI from official Docker apt repo
2. **tools-builder** — Python slim image, installs all tools via scripts/ into /usr/local/bin
3. **runtime** — Debian trixie-slim, copies binaries from builder stages, adds non-root user
4. **smoke-test** — extends runtime, runs --version on every tool to validate the build

The runtime image does NOT include build tools (curl, make etc used only during build).
Final image is Debian trixie-slim + copied binaries + tini entrypoint.

## Installed tools (current versions from versions.env)

### Kubernetes
- kubectl 1.34.1
- helm 3.19.0
- kustomize 5.7.1
- k3d 5.7.5

### Infrastructure as Code
- terraform 1.14.7
- opentofu 1.9.1
- packer 1.15.0
- ansible 10.7.0 + ansible-lint 25.1.3 (via pip in builder stage)

### Secrets
- vault 1.21.4
- sops 3.10.2
- age 1.2.1

### Security / Supply chain
- trivy 0.69.3
- grype 0.109.0
- syft 1.22.0
- gitleaks 8.28.0

### Container
- docker CLI 27.5.1 (from official Docker apt repo, not Docker Desktop)
- docker buildx plugin
- docker compose plugin

### Utilities
- jq (from apt)
- yq 4.47.2
- openssl (from apt)
- git, curl, wget, make, ssh client (from apt)
- tini (init process, entrypoint)

## How installer scripts work

Each `scripts/install-*.sh` follows the same pattern:
- Takes version as `$1`
- Sources `_common.sh` for shared helpers
- Uses `map_arch()` to translate dpkg arch (amd64/arm64) to tool-specific arch names
- Uses `download_file()` for curl with retry logic
- Installs binary to `/usr/local/bin/` with `chmod 0755`

Example:
```bash
bash scripts/install-kubectl.sh "1.34.1"
```

## How it is used in the Kubernetes PoC

The PoC project (`~/Projects/poc`) uses this image as its entire tool runtime.
Every kubectl, helm, vault, and k3d command is an alias that runs a container:

```bash
# Example alias from poc-toolkit.zsh
alias kubectl="docker run --rm -it --network host   -v ${HOME}/Projects/poc/manifests:/work   -v ${HOME}/Projects/poc/kube:/root/.kube   -v ${HOME}/Projects/poc/vault:/root/.vault   -e KUBECONFIG=/root/.kube/config   devops-toolkit:latest kubectl"
```

Key mount points the PoC uses:
- `~/Projects/poc/manifests` → `/work` (Kubernetes YAML)
- `~/Projects/poc/kube` → `/root/.kube` (kubeconfig)
- `~/Projects/poc/vault` → `/root/.vault` (Vault token path)
- `~/Projects/poc/helm-cache` → `/root/.cache/helm`
- `~/Projects/poc/helm-config` → `/root/.config/helm`
- `/var/run/docker.sock` → `/var/run/docker.sock` (for k3d)

### Known PoC-specific quirk
`VAULT_TOKEN_PATH=/root/.vault/token` is set in the PoC toolkit env. The Vault CLI
treats this as the token helper path. Since `/root/.vault` is a directory (not a file),
any `docker run` call that mounts `/root/.vault` AND invokes the vault CLI will fail
with "failed to get token helper: read /root/.vault: is a directory".

Workaround: do NOT mount `/root/.vault` in vault CLI docker run calls. Pass
`-e VAULT_TOKEN=<value>` explicitly instead. The PoC scripts handle this correctly.

## Adding a new tool

1. Create `scripts/install-newtool.sh` (takes version as $1, installs to /usr/local/bin/)
2. Add `NEWTOOL_VERSION=x.y.z` to `versions.env`
3. Add `ARG NEWTOOL_VERSION` to Dockerfile tools-builder stage
4. Add `RUN /tmp/build/scripts/install-newtool.sh "${NEWTOOL_VERSION}"` to Dockerfile
5. Add `--build-arg NEWTOOL_VERSION=$(NEWTOOL_VERSION)` to Makefile BUILD_ARGS
6. Add `@echo "NEWTOOL_VERSION=$(NEWTOOL_VERSION)"` to Makefile versions target
7. Add tool to smoke-test stage validation
8. Run `make smoke` to validate before `make build`

## CI integration

The image is designed to run in Gitea/GitHub/GitLab CI as a control container.
The Docker socket mount pattern avoids Docker-in-Docker. The non-root `devops`
user (UID/GID 1000) is used for local runs; CI runners typically run as root.

## AI working convention
Always request actual files before editing or generating derivatives.
No assumptions about current content — versions, tool list, or Dockerfile
structure may have changed since last session.
