# files/share/

Static content bundled into the built image at `/files/`.

Anything in this directory lands at `/files/` inside the running container,
preserving the directory structure underneath. For example,
`files/share/helm/values.yaml` ends up at `/files/helm/values.yaml`.

Use this for content that should be available at a predictable path but does
not need to be on `PATH`:

- Configuration templates
- Helper data files (manifests, values files, JSON/YAML fixtures)
- Documentation or license files bundled with the image

For executable scripts, use `files/bin/` instead — those land on `PATH` and
are callable by name.

This directory is empty by default. The `.gitkeep` and `README.md` are
tracked.
