# Cloud CLI Credentials — devops-toolkit:full

How to supply AWS and Azure credentials to the container for both interactive
use and Gitea Actions CI pipelines.

Two patterns are covered:

- **Environment variables** — good for CI, ephemeral tokens, and assumed roles
- **Mounted credential files** — good for interactive use with long-lived profiles

---

## AWS CLI

### Pattern A — Environment variables

Pass credentials directly as environment variables. Works with IAM users,
assumed roles, and temporary STS tokens.

```bash
docker run --rm -it \
  -e AWS_ACCESS_KEY_ID=AKIA... \
  -e AWS_SECRET_ACCESS_KEY=... \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

For temporary/assumed-role credentials add `AWS_SESSION_TOKEN`:

```bash
docker run --rm -it \
  -e AWS_ACCESS_KEY_ID=ASIA... \
  -e AWS_SECRET_ACCESS_KEY=... \
  -e AWS_SESSION_TOKEN=... \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

Using an env file to keep the shell history clean:

```bash
# ~/.aws-env  (chmod 600, never commit)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=us-east-1
```

```bash
docker run --rm -it \
  --env-file ~/.aws-env \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

### Pattern B — Mount credentials files

Mount the host `~/.aws` directory read-only. All profiles, regions, and SSO
config are available exactly as on the host.

```bash
docker run --rm -it \
  -v "${HOME}/.aws":/home/devops/.aws:ro \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

To use a specific named profile:

```bash
docker run --rm -it \
  -v "${HOME}/.aws":/home/devops/.aws:ro \
  -e AWS_PROFILE=my-profile \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

> **Note:** The mount target is `/home/devops/.aws` because the runtime user
> is `devops` (uid 1000). AWS CLI resolves credentials from `$HOME/.aws`.

---

## Azure CLI

### Pattern A — Environment variables

Azure CLI supports a service principal via environment variables using the
`AZURE_` prefix. This is the recommended pattern for CI.

```bash
docker run --rm -it \
  -e AZURE_TENANT_ID=... \
  -e AZURE_CLIENT_ID=... \
  -e AZURE_CLIENT_SECRET=... \
  -e AZURE_SUBSCRIPTION_ID=... \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

Azure CLI does not automatically pick up `AZURE_*` variables the way AWS CLI
does — you need to explicitly log in using them inside the container:

```bash
az login --service-principal \
  --tenant  "${AZURE_TENANT_ID}" \
  --username "${AZURE_CLIENT_ID}" \
  --password "${AZURE_CLIENT_SECRET}"

az account set --subscription "${AZURE_SUBSCRIPTION_ID}"
```

You can wrap this in a one-liner at container startup:

```bash
docker run --rm -it \
  -e AZURE_TENANT_ID=... \
  -e AZURE_CLIENT_ID=... \
  -e AZURE_CLIENT_SECRET=... \
  -e AZURE_SUBSCRIPTION_ID=... \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full \
  bash -c '
    az login --service-principal \
      --tenant  "${AZURE_TENANT_ID}" \
      --username "${AZURE_CLIENT_ID}" \
      --password "${AZURE_CLIENT_SECRET}" \
    && az account set --subscription "${AZURE_SUBSCRIPTION_ID}" \
    && exec bash
  '
```

Using an env file:

```bash
# ~/.azure-env  (chmod 600, never commit)
AZURE_TENANT_ID=...
AZURE_CLIENT_ID=...
AZURE_CLIENT_SECRET=...
AZURE_SUBSCRIPTION_ID=...
```

```bash
docker run --rm -it \
  --env-file ~/.azure-env \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full \
  bash -c '
    az login --service-principal \
      --tenant  "${AZURE_TENANT_ID}" \
      --username "${AZURE_CLIENT_ID}" \
      --password "${AZURE_CLIENT_SECRET}" \
    && az account set --subscription "${AZURE_SUBSCRIPTION_ID}" \
    && exec bash
  '
```

### Pattern B — Mount credentials files

After running `az login` on the host, Azure CLI stores its token cache under
`~/.azure`. Mount it read-write so the container can refresh tokens.

```bash
docker run --rm -it \
  -v "${HOME}/.azure":/home/devops/.azure \
  -v "$(pwd)":/workspace \
  --user 1000:1000 \
  devops-toolkit:full
```

> **Note:** Unlike `~/.aws`, the Azure token cache needs to be read-write
> because `az` refreshes access tokens automatically during the session.
> Mount it `:ro` only if you are certain the token will not expire mid-session.

---

## Both clouds together

All four mounts and env files can be combined freely:

```bash
docker run --rm -it \
  -v "${HOME}/.aws":/home/devops/.aws:ro \
  -v "${HOME}/.azure":/home/devops/.azure \
  -e AWS_PROFILE=my-profile \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -v "$(pwd)":/workspace \
  -v "${HOME}/.ssh":/home/devops/.ssh:ro \
  --user 1000:1000 \
  devops-toolkit:full
```

---

## Gitea Actions — CI pipeline usage

### AWS in CI

Store credentials as Gitea Actions secrets
(`Settings → Actions → Secrets`), then reference them in the workflow.

For IAM user keys:

```yaml
- name: Run Terraform plan
  env:
    AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_DEFAULT_REGION:    us-east-1
  run: |
    docker run --rm \
      -e AWS_ACCESS_KEY_ID \
      -e AWS_SECRET_ACCESS_KEY \
      -e AWS_DEFAULT_REGION \
      -v "${GITHUB_WORKSPACE}":/workspace \
      devops-toolkit:ci-iac \
      bash -c 'cd /workspace && terraform init && terraform plan'
```

For assumed-role / STS temporary credentials (e.g. OIDC or a prior
`aws sts assume-role` step):

```yaml
- name: Run Terraform plan
  env:
    AWS_ACCESS_KEY_ID:     ${{ steps.assume-role.outputs.aws-access-key-id }}
    AWS_SECRET_ACCESS_KEY: ${{ steps.assume-role.outputs.aws-secret-access-key }}
    AWS_SESSION_TOKEN:     ${{ steps.assume-role.outputs.aws-session-token }}
    AWS_DEFAULT_REGION:    us-east-1
  run: |
    docker run --rm \
      -e AWS_ACCESS_KEY_ID \
      -e AWS_SECRET_ACCESS_KEY \
      -e AWS_SESSION_TOKEN \
      -e AWS_DEFAULT_REGION \
      -v "${GITHUB_WORKSPACE}":/workspace \
      devops-toolkit:ci-iac \
      bash -c 'cd /workspace && terraform init && terraform plan'
```

### Azure in CI

Store the service principal values as secrets, then log in inside the step:

```yaml
- name: Run Terraform plan (Azure)
  env:
    AZURE_TENANT_ID:       ${{ secrets.AZURE_TENANT_ID }}
    AZURE_CLIENT_ID:       ${{ secrets.AZURE_CLIENT_ID }}
    AZURE_CLIENT_SECRET:   ${{ secrets.AZURE_CLIENT_SECRET }}
    AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  run: |
    docker run --rm \
      -e AZURE_TENANT_ID \
      -e AZURE_CLIENT_ID \
      -e AZURE_CLIENT_SECRET \
      -e AZURE_SUBSCRIPTION_ID \
      -v "${GITHUB_WORKSPACE}":/workspace \
      devops-toolkit:ci-iac \
      bash -c '
        az login --service-principal \
          --tenant  "${AZURE_TENANT_ID}" \
          --username "${AZURE_CLIENT_ID}" \
          --password "${AZURE_CLIENT_SECRET}" \
        && az account set --subscription "${AZURE_SUBSCRIPTION_ID}" \
        && cd /workspace \
        && terraform init \
        && terraform plan
      '
```

> **Tip:** The bare `-e VARNAME` form (no `=value`) passes the variable from
> the step's `env:` block into the container without repeating the value in
> the `run:` shell — keeping secrets out of the process argument list and
> out of runner logs.

---

## Quick reference

| Credential | Interactive (file mount) | CI (env var) |
|---|---|---|
| AWS long-lived key | `-v ~/.aws:/home/devops/.aws:ro` | `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` |
| AWS named profile | above + `-e AWS_PROFILE=name` | n/a |
| AWS temp token | n/a | above + `AWS_SESSION_TOKEN` |
| AWS region | `-e AWS_DEFAULT_REGION=...` | `-e AWS_DEFAULT_REGION=...` |
| Azure interactive login | `-v ~/.azure:/home/devops/.azure` | n/a |
| Azure service principal | n/a | `AZURE_*` vars + `az login --service-principal` |
