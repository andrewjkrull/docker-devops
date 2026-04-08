# DevOps Toolkit — AI Session Context

## What this repository is
A Docker image project providing a reproducible, version-pinned DevOps toolbox.
Produces one full local image and three purpose-built lean CI runner images.

## Repository structure

```
docker-devops/
├── Dockerfile              # :full image — everything, for local interactive use
├── Makefile                # all build / smoke / run targets
├── versions.env            # ALL tool versions pinned here — single source of truth
├── README.md
├── toolkit-CONTEXT.md      # this file
│
├── scripts/
│   ├── _common.sh          # log(), err(), require_version(), map_arch(), download_file()
│   ├── install-ansible.sh  # takes CORE_VERSION LINT_VERSION — uses ansible-core, not community
│   ├── install-terraform.sh
│   ├── install-opentofu.sh
│   ├── install-packer.sh
│   ├── install-vault.sh
│   ├── install-kubectl.sh
│   ├── install-helm.sh
│   ├── install-kustomize.sh
│   ├── install-k3d.sh
│   ├── install-trivy.sh
│   ├── install-grype.sh
│   ├── install-syft.sh
│   ├── install-gitleaks.sh
│   ├── install-yq.sh
│   ├── install-sops.sh
│   └── install-age.sh
│
└── ci/
    ├── Dockerfile.k8s      # :ci-k8s  — kubectl, helm, kustomize, yq, sops, age, docker
    ├── Dockerfile.security # :ci-security — trivy, grype, syft, gitleaks, docker
    └── Dockerfile.iac      # :ci-iac  — terraform, tofu, vault, sops, age, yq
```

## Images produced

| Tag | Purpose | Key contents |
|-----|---------|--------------|
| `:full` / `:latest` | Local interactive | Everything — all tools + vim + k3d + ansible |
| `:ci-k8s` | GitOps deploy steps | kubectl, helm, kustomize, yq, sops, age, docker |
| `:ci-security` | Scan steps | trivy, grype, syft, gitleaks, docker |
| `:ci-iac` | IaC provisioning | terraform, tofu, vault, sops, age, yq |

## Build system

Versions controlled exclusively via `versions.env`.
Makefile reads the file, exports all vars, passes each relevant one as `--build-arg`.

```bash
make build          # devops-toolkit:full (also :latest)
make smoke          # smoke-test full image
make run            # interactive shell
make ci-all         # build all three CI images
make ci-smoke-all   # smoke-test all CI images
make versions       # print all pinned versions
make clean          # remove all images
```

## Key design decisions

### ansible-core vs ansible community package
Using `ansible-core` only. The community `ansible` package (~150MB larger) bundles
hundreds of third-party collection modules rarely needed. `ansible-core` includes
the engine and standard library. Additional collections added via `ansible-galaxy`
at runtime or in derived images if needed.

### install-ansible.sh signature change
Old: called from Dockerfile as two separate pip installs.
New: `scripts/install-ansible.sh "${ANSIBLE_CORE_VERSION}" "${ANSIBLE_LINT_VERSION}"`
Takes both versions as positional args.

### Terraform install method
Still uses the HashiCorp apt repo (install-terraform.sh). The zip-based alternative
(install-terraform.sh-viaZip) exists and works — switching to it would simplify the
build layer but requires testing. Not changed in this iteration.

### k3d placement
Only in `:full`. Not in any CI image. k3d creates clusters; CI jobs run against
an existing cluster.

### vim / iproute2 / iputils-ping / wget
Only in `:full`. These are interactive convenience tools — no pipeline job needs them.
`wget` removed entirely (curl covers all use cases, all install scripts already use curl).

## Dockerfile stage pattern (same across all files)

1. `docker-cli-source` — installs Docker CE CLI from official Docker apt repo
2. `tools-builder` — installs only the tools this image needs, using scripts/
3. `runtime` — debian-slim + minimal apt packages + COPY binaries from builders
4. `smoke-test` — extends runtime, runs --version on every included tool

## Adding a new tool

Full image:
1. Create `scripts/install-newtool.sh` (takes version as $1)
2. Add `NEWTOOL_VERSION=x.y.z` to `versions.env`
3. Add `ARG NEWTOOL_VERSION` to tools-builder in `Dockerfile`
4. Add `RUN /tmp/build/scripts/install-newtool.sh "${NEWTOOL_VERSION}"` to `Dockerfile`
5. Add `--build-arg NEWTOOL_VERSION=$(NEWTOOL_VERSION)` to `FULL_BUILD_ARGS` in `Makefile`
6. Add `COPY --from=tools-builder /usr/local/bin/newtool /usr/local/bin/newtool` to runtime stage
7. Add smoke-test line and `make versions` echo
8. `make smoke` before `make build`

CI image: same pattern on the relevant `ci/Dockerfile.*` and add to corresponding
`*_BUILD_ARGS` block in Makefile.

## How this is used in the PoC

The PoC project (`~/Projects/poc`) uses `:full` as its tool runtime via aliases:

```bash
alias kubectl="docker run --rm -it --network host \
  -v ${HOME}/Projects/poc/manifests:/work \
  -v ${HOME}/Projects/poc/kube:/root/.kube \
  -e KUBECONFIG=/root/.kube/config \
  devops-toolkit:full kubectl"
```

Key mount points:
- `~/Projects/poc/manifests` → `/work`
- `~/Projects/poc/kube` → `/root/.kube`
- `/var/run/docker.sock` → `/var/run/docker.sock` (for k3d)

### Vault mount quirk
`VAULT_TOKEN_PATH=/root/.vault/token` in PoC toolkit env.
Vault CLI treats this as the token helper path. Mounting `/root/.vault` as a
directory causes "failed to get token helper: read /root/.vault: is a directory".
Workaround: do NOT mount `/root/.vault`; pass `-e VAULT_TOKEN=<value>` explicitly.

## AI working conventions
- Always request actual files before editing — never assume current content
- No heredocs (reliability issues in devops-toolkit container)
- Scripts: consistent log()/warn()/die() pattern, Vault credential retrieval, idempotent ops
- Prefer thorough root cause fixes over workarounds
