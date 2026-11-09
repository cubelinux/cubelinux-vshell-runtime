# syntax=docker/dockerfile:1

FROM registry.fedoraproject.org/fedora:44

# Tell systemd that it is running as the init process inside an LXC container.
ENV container=lxc

RUN dnf -y \
        --setopt=install_weak_deps=False \
        --exclude='PackageKit*' \
        --exclude='plasma-discover-kns*' \
        --exclude='plasma-discover-offline-updates*' \
        --exclude='plasma-discover-packagekit*' \
        --exclude='plasma-discover-rpm-ostree*' \
        --exclude='plasma-discover-snap*' \
        --exclude='rpm-ostree*' \
        install \
        dbus-broker \
        flatpak \
        plasma-discover \
        plasma-discover-flatpak \
        shadow-utils \
        sudo \
        systemd && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# The host-mounted X11 socket path is fixed. VShell configures the slirp4netns
# resolver inside each LXC instance during first setup.
RUN mkdir -p /etc/tmpfiles.d && \
    printf '%s\n' \
        'L+ /tmp/.X11-unix - - - - /mnt/vshell-host-x11' \
        > /etc/tmpfiles.d/cubelinux-vshell-x11.conf

STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
