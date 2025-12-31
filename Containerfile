# NOTE: Tailscale requires userspace networking mode on FreeBSD Podman
# The container needs --device /dev/tun for tunnel creation
#
# This Containerfile serves both :latest and :pkg tags
# (io.daemonless.pkg-source="containerfile" - installed via pkg)

ARG BASE_VERSION=15
FROM ghcr.io/daemonless/base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="tailscale"
ARG UPSTREAM_URL="https://api.github.com/repos/tailscale/tailscale/releases/latest"
ARG UPSTREAM_JQ=".tag_name"

LABEL org.opencontainers.image.title="Tailscale" \
    org.opencontainers.image.description="Tailscale mesh VPN on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/tailscale" \
    org.opencontainers.image.url="https://tailscale.com/" \
    org.opencontainers.image.documentation="https://tailscale.com/kb/" \
    org.opencontainers.image.licenses="BSD-3-Clause" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.network="host" \
    io.daemonless.pkg-source="containerfile" \
    io.daemonless.category="Infrastructure" \
    io.daemonless.upstream-url="${UPSTREAM_URL}" \
    io.daemonless.upstream-jq="${UPSTREAM_JQ}" \
    io.daemonless.healthcheck-url="tailscale-status" \
    io.daemonless.packages="${PACKAGES}"

# Install Tailscale from FreeBSD packages
RUN pkg update && \
    pkg install -y ${PACKAGES} && \
    mkdir -p /app && pkg info tailscale | sed -n 's/.*Version.*: *//p' > /app/version && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Create state directory
RUN mkdir -p /var/db/tailscale && \
    chmod 700 /var/db/tailscale

# Copy service definition and init scripts
COPY root/ /

# Make scripts executable
RUN chmod +x /etc/services.d/tailscaled/run /etc/cont-init.d/* /healthz 2>/dev/null || true

# Set up s6 service link

VOLUME /var/db/tailscale


