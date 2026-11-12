# cubelinux VShell Runtime

This project builds the Fedora user-space image used by cubelinux VShell. It is
separate from the bootc desktop image and is intended to be imported and run as
an LXC system container. LXC uses the host kernel; this image does not boot a
second kernel or use `bootc upgrade` inside the guest.

## Initial contents

The Fedora 44 OCI image includes systemd for the LXC init process, D-Bus,
Flatpak, KDE Discover with its Flatpak backend, `iproute` for first-time guest network
setup, `sudo`, and user account tools.
Discover's PackageKit/RPM, RPM-OSTree, Snap, KNewStuff, and offline-update
backends are excluded. Fedora's `dnf` and RPM tools remain available in the
guest shell; this only limits Discover to Flatpak.
VShell launches Discover with a short-lived private D-Bus session because it cannot register its KDE D-Bus service on the forwarded host session bus.

The image does not bake in a username or home directory. VShell creates the
guest account and mounts the signed-in user's home when it starts the runtime.

The image includes empty `/mnt/vshell-host-runtime` and `/mnt/vshell-host-x11`
directories for LXC's host desktop bind mounts. They must exist in the image
because VShell mounts the system filesystem read-only after setup.

VShell configures Flathub as a user-scoped remote inside the shared home when
the runtime starts. If the network is unavailable, setup continues and VShell
retries the remote setup the next time it opens. The image installs no Flatpak
applications. Flatpak sandbox behavior inside rootless LXC still needs to be
validated.

The slirp4netns DNS address (`10.0.2.3`) is configured inside the LXC instance
during first setup, when VShell knows which user-mode network it starts. It is
not written to `/etc/resolv.conf` during the image build.

## Build

Build the OCI image from this directory with Podman or Docker:

```sh
podman build -f Containerfile -t cubelinux-vshell-runtime:44 .
```

## Published image

The GitHub Actions workflow publishes the multi-architecture runtime image to
`ghcr.io/cubelinux/cubelinux-vshell-runtime`. It uses the same tag scheme as
the main cubelinux image:

- The branch or Git ref name, such as `main`.
- Full and short commit tags, such as `sha-<full-commit>` and `sha-<short-commit>`.
- `latest` on each successful workflow run.
- Semantic version tags, such as `v1.2.3`, also publish `1.2.3`, `1.2`, and `1`.

Before publishing the final tags, the workflow uses
[Chunkah](https://github.com/coreos/chunkah) to split the `amd64` and `arm64`
root filesystems into content-based OCI layers, then
publishes them together as a multi-architecture image. This keeps the Runtime
as a regular OCI image for LXC while allowing unchanged package layers to be
reused when a new Runtime image is pulled.

The host image does not bundle this Runtime OCI image. At the first KDE login
after Plasma Setup, VShell pulls the mutable `:main` tag from GHCR and creates
the user's `cubelinux-runtime` LXC instance. This first setup needs an internet
connection. Later logins start the existing container. Runtime releases do not
require a host image rebuild, and the guest does not run `bootc upgrade`.

## State and reset behavior

The LXC instance's system files are mounted read-only after VShell has created
the guest account. `/tmp` and `/var` are temporary writable filesystems. The
shared `/home/<user>` is the only default persistent writable mount, so
per-user Flatpak installs and the user-scoped Flathub remote survive recreating
the container. Reset pulls the current `:main` image from GHCR and requires
internet access. There is no persistent system Flatpak store. Additional host
folders can still be shared read-write when explicitly configured in VShell
settings. VShell mounts the guest's `/proc` read-write so Bubblewrap can create
the nested proc filesystem required by Flatpak. This also makes `/proc/sys`
read-write at the guest mount level, subject to kernel namespace and capability
checks. It changes only the unprivileged guest's proc mount, not the host's
`/proc` or bootc image.

## License

cubelinux VShell Runtime project files are licensed under GPL-3.0-or-later.
See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT). Fedora and other software
included in the image retain their own licenses.
