FROM debian:bookworm@sha256:b91baba9c2cae5edbe3b0ff50ae8f05157e3ae6f018372dcfc3aba224acb392b

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG CONTAINERD_UPSTREAM_PREFIX

ENV USERNAME="builder"
WORKDIR "/build"

# required to install build deps for a pkg
RUN <<_EOF_
sed \
    --in-place \
    's/Types: deb/Types: deb deb-src/g' \
    "/etc/apt/sources.list.d/debian.sources"
_EOF_

RUN <<_EOF_
apt-get update
apt-get install --assume-yes "build-essential" "protobuf-compiler"
apt-get build-dep --assume-yes "containerd"
_EOF_

RUN <<_EOF_
groupadd --gid "${HOST_GID}" "${USERNAME}"
useradd \
    --uid "${HOST_UID}" \
    --gid "${HOST_GID}" \
    "${USERNAME}"
_EOF_

WORKDIR "/build/${CONTAINERD_UPSTREAM_PREFIX}"
USER "${USERNAME}"

# DEB_BUILD_OPTIONS=nocheck to ignore running tests after building the pkg, see
# https://manpages.debian.org/testing/debhelper/dh_auto_test.1.en.html
ENTRYPOINT [ \
    "/bin/bash", \
    "-c", \
    "DEB_BUILD_OPTIONS=\"nocheck\" dpkg-buildpackage --build=\"binary\"" \
]
