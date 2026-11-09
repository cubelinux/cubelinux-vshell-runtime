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

# VShell uses a fixed slirp4netns DNS proxy and a host-mounted X11 socket path.
# Bake these into the immutable runtime so VShell never has to edit /etc after
# the container has been made read-only.
RUN rm -f /etc/resolv.conf && \
    printf 'nameserver 10.0.2.3\n' > /etc/resolv.conf && \
    mkdir -p /etc/tmpfiles.d && \
    printf '%s\n' \
        'L+ /tmp/.X11-unix - - - - /mnt/vshell-host-x11' \
        > /etc/tmpfiles.d/cubelinux-vshell-x11.conf

STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
