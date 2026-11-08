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

# Preconfigure Flathub for all users; this adds the remote but installs no apps.
ADD https://dl.flathub.org/repo/flathub.flatpakrepo \
    /etc/flatpak/remotes.d/flathub.flatpakrepo

STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
