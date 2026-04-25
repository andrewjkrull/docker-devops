# files/bin/

Custom scripts bundled into the built image at `/files/bin/`, on `PATH`.

Anything in this directory becomes callable by name inside the running
container. `/files/bin/` is appended to `PATH` *after* the standard system
paths, so scripts here add commands but do not shadow system tools of the
same name.

Make scripts executable before committing:

```
chmod +x files/bin/myhelper.sh
```

The Dockerfile applies `chmod +x /files/bin/*` at build time as a safeguard,
but committing scripts as executable is the cleaner habit.

This directory is empty by default. The `.gitkeep` and `README.md` are
tracked.
