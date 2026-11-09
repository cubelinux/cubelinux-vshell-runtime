# CubeLinux VShell Runtime

This project builds the Fedora user-space image used by CubeLinux VShell. It is
separate from the bootc desktop image and is intended to be imported and run as
an LXC system container. LXC uses the host kernel; this image does not boot a
second kernel or use `bootc upgrade` inside the guest.

## Initial contents

The Fedora 44 OCI image includes systemd for the LXC init process, D-Bus,
Flatpak, KDE Discover with its Flatpak backend, `sudo`, and user account tools.
Discover's PackageKit/RPM, RPM-OSTree, Snap, KNewStuff, and offline-update
backends are excluded. Fedora's `dnf` and RPM tools remain available in the
guest shell; this only limits Discover to Flatpak.

The image does not bake in a username or home directory. VShell creates the
guest account and mounts the signed-in user's home when it starts the runtime.
The LXC instance's system files become read-only after setup. `/tmp` and `/var`
remain temporary writable filesystems for instance state. The shared
`/home/<user>` is the only default persistent writable mount; it preserves the
user's Flatpak configuration and per-user app installs across resets. There is
no separate persistent system Flatpak store.

VShell configures Flathub as a user-scoped remote inside the shared home when
the runtime starts. If the network is unavailable, setup continues and VShell
retries the remote setup the next time it opens. The image installs no Flatpak
applications. Flatpak sandbox behavior inside rootless LXC still needs to be
validated.

## Build

Build the OCI image from this directory with Podman or Docker:

```sh
podman build -f Containerfile -t cubelinux-vshell-runtime:44 .
```

## Published image

The GitHub Actions workflow publishes the multi-architecture runtime image to
`ghcr.io/cubelinux/cubelinux-vshell-runtime`. It uses the same tag scheme as
the main CubeLinux image:

- The branch or Git ref name, such as `main`.
- Full and short commit tags, such as `sha-<full-commit>` and `sha-<short-commit>`.
- `latest` on each successful workflow run.
- Semantic version tags, such as `v1.2.3`, also publish `1.2.3`, `1.2`, and `1`.

The cubelinux host image bundles the published Runtime OCI image as an offline
source. After Plasma Setup, VShell creates the user's LXC Runtime instance from
that local copy; it does not bundle an LXC instance with host-specific account
and network settings. Reset Runtime pulls the mutable `:main` tag from GHCR, so
users can get a newer Runtime without first updating the host image. The
bundled image changes when the host image is rebuilt, so publish this Runtime
image before building a host image that should include a newer version. The
guest does not run `bootc upgrade`.

## State and reset behavior

The LXC instance's system files are mounted read-only after VShell has created
the guest account. `/tmp` and `/var` are temporary writable filesystems. The shared
`/home/<user>` is the only default persistent writable mount, so per-user
Flatpak installs and the user-scoped Flathub remote survive recreating the
container. The first LXC instance is created locally from the OCI image
bundled in the host image and does not require internet access to fetch
Runtime. Reset requires internet
access to resolve and pull the current `:main` image from GHCR. There is no
persistent system Flatpak store. Additional host folders can still be shared
read-write when explicitly configured in VShell settings. Any Flatpak sandbox
limitations in rootless LXC must be validated before relying on this workflow.

## License

CubeLinux VShell Runtime project files are licensed under GPL-3.0-or-later.
See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT). Fedora and other software
included in the image retain their own licenses.
