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

The image preconfigures Flathub as a system-wide Flatpak remote, but does not
install any Flatpak applications. The default app list and Flatpak sandbox
behavior inside rootless LXC still need to be settled and validated.

## Build

Build the OCI image from this directory with Podman or Docker:

```sh
podman build -f Containerfile -t cubelinux-vshell-runtime:44 .
```

## Published image

The GitHub Actions workflow publishes the multi-architecture runtime image to
`ghcr.io/cubelinux/vshell-runtime`. It uses the same tag scheme as the main
CubeLinux image:

- The branch or Git ref name, such as `main`.
- Full and short commit tags, such as `sha-<full-commit>` and `sha-<short-commit>`.
- `latest` on each successful workflow run.
- Semantic version tags, such as `v1.2.3`, also publish `1.2.3`, `1.2`, and `1`.

The image is a build artifact. VShell will need an import/update path that
creates its LXC root filesystem from a selected image version. Updating the
runtime means replacing that root filesystem from a newer image, not running
`bootc upgrade` inside LXC.

## State and reset behavior

The intended runtime layout is a read-only image base with a disposable
writable layer. VShell should keep user data in separately managed mounts so a
runtime reset can discard the writable layer without deleting the user's
files.

Flatpak system installations live under `/var/lib/flatpak` and can be baked
into a runtime image once the default app list is chosen. Flatpak per-user
installations live under the user's data directory. VShell currently shares
the host home with the guest, so `flatpak install --user` writes into the host
home and survives replacing the LXC root filesystem. Any Flatpak sandbox
limitations in rootless LXC must be tested before relying on this workflow.

## License

CubeLinux VShell Runtime project files are licensed under GPL-3.0-or-later.
See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT). Fedora and other software
included in the image retain their own licenses.
