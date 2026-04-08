# DevOps Toolkit Container

A reproducible, version-pinned DevOps toolbox built for local development, GitOps workflows,
and CI/CD pipelines.  All tool versions are controlled from a single file (`versions.env`).

---

## Images

| Tag | Use case | Approx. size |
|-----|----------|-------------|
| `devops-toolkit:full` | Local interactive development | ~900 MB |
| `devops-toolkit:ci-k8s` | CI — Kubernetes deploy steps | ~250 MB |
| `devops-toolkit:ci-security` | CI — security scanning steps | ~400 MB |
| `devops-toolkit:ci-iac` | CI — infrastructure provisioning steps | ~350 MB |

`full` is the daily driver image — it contains everything.
The `ci-*` images are purpose-built for specific pipeline stages: lean, fast to pull, no extras.

---

## Quick start

```bash
# Build the local full image
make build

# Interactive shell with workspace + Docker socket mounted
make run

# Build all CI runner images
make ci-all

# Smoke-test everything
make smoke
make ci-smoke-all
```

---

## Repository layout

```
docker-devops/
├── Dockerfile              # :full image (everything)
├── Makefile
├── versions.env            # single source of truth for all versions
├── README.md
├── toolkit-CONTEXT.md      # AI session handoff document
│
├── scripts/
│   ├── _common.sh          # shared helpers: log(), map_arch(), download_file()
│   ├── install-ansible.sh  # takes CORE_VERSION LINT_VERSION
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

---

## Tool inventory

### Full image (:full)

| Category | Tools |
|----------|-------|
| Kubernetes | kubectl, helm, kustomize, k3d |
| IaC | terraform, opentofu, packer |
| Config mgmt | ansible-core + ansible-lint |
| Secrets | vault, sops, age |
| Security | trivy, grype, syft, gitleaks |
| Container | docker CLI, buildx, compose |
| Utilities | jq, yq, git, curl, make, openssh, tini, vim |

### CI images — what each one includes

| Tool | ci-k8s | ci-security | ci-iac |
|------|--------|-------------|--------|
| kubectl | yes | - | - |
| helm | yes | - | - |
| kustomize | yes | - | - |
| yq | yes | - | yes |
| sops | yes | - | yes |
| age | yes | - | yes |
| docker CLI | yes | yes | - |
| trivy | - | yes | - |
| grype | - | yes | - |
| syft | - | yes | - |
| gitleaks | - | yes | - |
| terraform | - | - | yes |
| opentofu | - | - | yes |
| vault | - | - | yes |

---

## Makefile reference

### Full image

| Target | Description |
|--------|-------------|
| `make build` | Build `devops-toolkit:full` (also tags `:latest`) |
| `make smoke` | Build to smoke-test stage; validates all tools |
| `make run` | Interactive shell with workspace + Docker socket |

### CI images

| Target | Description |
|--------|-------------|
| `make ci-k8s` | Build `devops-toolkit:ci-k8s` |
| `make ci-security` | Build `devops-toolkit:ci-security` |
| `make ci-iac` | Build `devops-toolkit:ci-iac` |
| `make ci-all` | Build all three CI images |
| `make ci-smoke-k8s` | Smoke-test ci-k8s |
| `make ci-smoke-sec` | Smoke-test ci-security |
| `make ci-smoke-iac` | Smoke-test ci-iac |
| `make ci-smoke-all` | Smoke-test all CI images |

### Housekeeping

| Target | Description |
|--------|-------------|
| `make versions` | Print all pinned versions |
| `make clean` | Remove all built images |

Override image name or tag:

```bash
make build IMAGE_NAME=myregistry.local/devops-toolkit IMAGE_TAG=1.2.3
make ci-k8s IMAGE_NAME=myregistry.local/devops-toolkit
```

---

## Version management

All versions live in `versions.env` — one file, one change to update any tool:

```bash
# versions.env
KUBECTL_VERSION=1.34.1
HELM_VERSION=3.19.0
TRIVY_VERSION=0.69.3
# ...
```

The Makefile reads `versions.env` and passes every version as a `--build-arg`.
To update a tool: change the version in `versions.env` and rebuild.

---

## Gitea Actions — using the CI images

Reference the image directly in your workflow steps.
The Docker socket is available inside Gitea Actions runners that use the
`docker-outside-of-docker` pattern (socket mounted at `/var/run/docker.sock`).

```yaml
# .gitea/workflows/deploy.yaml
jobs:
  deploy:
    runs-on: self-hosted
    container:
      image: devops-toolkit:ci-k8s
    steps:
      - uses: actions/checkout@v4

      - name: Deploy with Helm
        run: |
          helm upgrade --install myapp ./charts/myapp \
            --namespace myapp \
            --values values.prod.yaml
```

```yaml
# .gitea/workflows/scan.yaml
jobs:
  scan:
    runs-on: self-hosted
    container:
      image: devops-toolkit:ci-security
    steps:
      - uses: actions/checkout@v4

      - name: Scan image
        run: |
          trivy image myapp:${GITEA_SHA}
          grype myapp:${GITEA_SHA}
          syft myapp:${GITEA_SHA} -o spdx-json > sbom.json
```

```yaml
# .gitea/workflows/infra.yaml
jobs:
  plan:
    runs-on: self-hosted
    container:
      image: devops-toolkit:ci-iac
    steps:
      - uses: actions/checkout@v4

      - name: Terraform plan
        run: |
          terraform init
          terraform plan
```

---

## Extending the toolkit

To add a new tool to the full image:

1. Create `scripts/install-newtool.sh` (takes version as `$1`, installs to `/usr/local/bin/`)
2. Add `NEWTOOL_VERSION=x.y.z` to `versions.env`
3. Add `ARG NEWTOOL_VERSION` to the `tools-builder` stage in `Dockerfile`
4. Add `RUN /tmp/build/scripts/install-newtool.sh "${NEWTOOL_VERSION}"` to `Dockerfile`
5. Add `--build-arg NEWTOOL_VERSION=$(NEWTOOL_VERSION)` to `FULL_BUILD_ARGS` in `Makefile`
6. Add the binary `COPY --from=tools-builder` line to the `runtime` stage in `Dockerfile`
7. Add a `make versions` print line and a smoke-test check
8. Run `make smoke` before `make build`

To add the tool to a CI image, apply the same pattern to the relevant `ci/Dockerfile.*`.

---

## Ansible note

The full image uses `ansible-core` rather than the community `ansible` mega-package.
`ansible-core` includes the engine, the standard library of modules, and `ansible-lint`.
The community package adds hundreds of third-party collections that are rarely needed.

If your playbooks require specific community collections, install them at runtime:

```bash
ansible-galaxy collection install community.general
```

Or bake them into a derived image:

```dockerfile
FROM devops-toolkit:full
RUN ansible-galaxy collection install community.general community.kubernetes
```

---

## Notes on tool choices

**Terraform and OpenTofu** — both are included. They are functionally equivalent for
this PoC. To drop one, comment out its version in `versions.env` and remove its
`ARG`/`RUN`/`COPY` lines from the relevant Dockerfiles.

**k3d** — only in the full image. It's a local cluster management tool, not needed
in CI pipeline steps that operate against an existing cluster.

**Packer** — only in the full image and `ci-iac`. Useful for building VM images as
part of an IaC workflow; not needed for Kubernetes deploy or security scan steps.
