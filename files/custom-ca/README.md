# files/custom-ca/

Additional root CA certificates trusted by the built image.

Drop `.crt` files here before building. The Dockerfile copies them to
`/usr/local/share/ca-certificates/custom-ca/` and runs `update-ca-certificates`,
which adds them to the system trust store.

This directory is empty by default. Vanilla builds trust only the standard
public CA bundle. The opt-in pattern is for environments with internal
certificate authorities (homelabs, corporate networks, internal PKI).

`.crt` and `.pem` files in this directory are gitignored repo-wide. The
`.gitkeep` and `README.md` are tracked.

## CI usage

Pipelines that need to trust an internal CA copy the cert into this directory
before invoking the build:

```yaml
- name: Inject internal CA
  run: cp /etc/ssl/certs/internal-ca.crt files/custom-ca/internal-ca.crt
```

The build step then proceeds normally — no Dockerfile change needed per
environment.
