#!/bin/bash
# Builds fluent-bit for arm64 or armhf and packages it into the fluentbit deb.
set -euo pipefail

FLUENTBIT_VERSION=5.0.9+nureva.2
FLUENTBIT_COMMIT=a1e05fc1f703fe0ab0373578896f395a04a7eeb5
FLUENTBIT_SHA256=04c0a2680be0438f6f23eabc664f259b3b81f2a4d4332563a8691dc41cce404a
ARM64_IMAGE=nurevaromedev.azurecr.io/cross-rs/aarch64-unknown-linux-gnu_24.04:latest

usage() {
    echo "Usage: $0 <arm64|armhf>" >&2
    exit 1
}

check_arm64_prereqs() {
    if ! command -v docker > /dev/null; then
        echo "arm64 is built with Docker, so Docker needs to be installed and logged in to nurevaromedev.azurecr.io (ex. 'just az-docker-login' in iotplatform)" >&2
        exit 1
    fi
}

check_armhf_prereqs() {
    local machine
    machine=$(uname -m)
    if [ "$machine" != "armv7l" ]; then
        echo "armhf needs to be built on an armhf device (ex. a RPi running Ubuntu 20.04), but this is $machine" >&2
        exit 1
    fi

    local deps=(build-essential bison flex patch pkg-config libssl-dev libsystemd-dev libyaml-dev zlib1g-dev)
    local install_count
    install_count=$(dpkg-query -l "${deps[@]}" 2> /dev/null | grep -c "^ii" || true)
    if [ "$install_count" -ne "${#deps[@]}" ]; then
        echo "Please run 'sudo apt install -y ${deps[*]}' to install dependencies" >&2
        exit 1
    fi

    local cmake_version
    cmake_version=$(cmake --version 2> /dev/null | sed -n 's/^cmake version //p' || true)
    if [ -z "$cmake_version" ] || ! dpkg --compare-versions "$cmake_version" ge 3.20.6; then
        echo "CMake needs to be 3.20.6 or newer (found ${cmake_version:-none}), so you would need to install a newer version since the one from apt on Ubuntu 20.04 is too old" >&2
        exit 1
    fi
}

check_configure_log() {
    if grep -E "Could NOT find (OpenSSL|Journald)" "$CONFIGURE_LOG"; then
        echo "CMake couldn't find OpenSSL or Journald, so fluent-bit would come out without TLS or the systemd input (see $CONFIGURE_LOG)" >&2
        exit 1
    fi
}

build_arm64() {
    CONTAINER=fluentbit-arm64-build-$$
    trap 'docker rm -f -v "$CONTAINER" > /dev/null' EXIT
    docker run -d --name "$CONTAINER" "$ARM64_IMAGE" sleep infinity > /dev/null
    docker cp build "$CONTAINER:/ppa-build"
    docker cp "$TARBALL" "$CONTAINER:/src.tar.gz"

    docker exec "$CONTAINER" bash -euxc '
        apt-get update
        apt-get install --no-install-recommends --assume-yes bison flex patch
        apt-get install --no-install-recommends --assume-yes libsystemd-dev:arm64 libyaml-dev:arm64 zlib1g-dev:arm64
        # Same libssl workaround as libs/iothubsdk/Cross.toml in iotplatform
        cd /tmp
        apt-get download libssl3t64:arm64 libssl-dev:arm64
        dpkg --purge --force-all libssl3t64
        dpkg --install --force-depends libssl3t64_*.deb
        dpkg --install libssl-dev_*.deb
        rm ./*.deb
    '

    docker exec "$CONTAINER" bash -euxc '
        mkdir -p /src /cmake-build
        tar -xzf /src.tar.gz -C /src --strip-components=1
        patch -d /src -p1 < /ppa-build/fluent-bit-native-minimal.patch
        cd /cmake-build
        export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
        # CROSS_SYSROOT needs to be unset, otherwise CMake does not find OpenSSL and Journald
        env -u CROSS_SYSROOT -u CROSS_CMAKE_OBJECT_FLAGS cmake -C /ppa-build/fluent-bit-native-minimal.cmake ../src -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=/opt/toolchain.cmake
    ' 2>&1 | tee "$CONFIGURE_LOG"
    check_configure_log

    docker exec "$CONTAINER" bash -euxc '
        cd /cmake-build
        export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
        cmake --build . -- -j"$(nproc)"
    '

    docker cp "$CONTAINER:/cmake-build/bin/fluent-bit" "$BINARY"
    docker rm -f -v "$CONTAINER" > /dev/null
    trap - EXIT
}

build_armhf() {
    local src_dir=$WRK_DIR/armhf/src
    local build_dir=$WRK_DIR/armhf/cmake-build
    local cmake_profile=$PWD/build/fluent-bit-native-minimal.cmake
    rm -rf "$src_dir" "$build_dir"
    mkdir -p "$src_dir" "$build_dir"
    tar -xzf "$TARBALL" -C "$src_dir" --strip-components=1
    patch -d "$src_dir" -p1 < build/fluent-bit-native-minimal.patch
    (cd "$build_dir" && cmake -C "$cmake_profile" ../src -G "Unix Makefiles") 2>&1 | tee "$CONFIGURE_LOG"
    check_configure_log
    (cd "$build_dir" && cmake --build . -- -j"$(nproc)")

    cp "$build_dir/bin/fluent-bit" "$BINARY"
    # The Pi doesn't have much disk space, so only the tarball and binary are kept
    rm -rf "$src_dir" "$build_dir"
}

[ "$#" -eq 1 ] || usage
ARCH=$1

case "$ARCH" in
    arm64)
        ELF_CLASS=ELF64
        ELF_MACHINE=AArch64
        DEPENDS="ca-certificates, libc6, libgcc-s1, libssl3t64 | libssl3, libstdc++6, libsystemd0, libyaml-0-2, zlib1g"
        COMPRESSION=zstd
        ;;
    armhf)
        ELF_CLASS=ELF32
        ELF_MACHINE=ARM
        DEPENDS="ca-certificates, libgcc-s1, libssl1.1, libstdc++6, libsystemd0, libyaml-0-2, zlib1g"
        # dpkg on Ubuntu 20.04 can't read zstd
        COMPRESSION=xz
        ;;
    *)
        usage
        ;;
esac

cd "$(dirname "$0")/.."

DEB_FILE=fluentbit_${FLUENTBIT_VERSION}_${ARCH}.deb
if [ -e "$DEB_FILE" ]; then
    echo "$DEB_FILE already exists, bump FLUENTBIT_VERSION in bin/build_deb.sh" >&2
    exit 1
fi

"check_${ARCH}_prereqs"

WRK_DIR=$PWD/.wrk
TARBALL=$WRK_DIR/src.tar.gz
CONFIGURE_LOG=$WRK_DIR/$ARCH/cmake-configure.log
BINARY=$WRK_DIR/$ARCH/fluent-bit
mkdir -p "$WRK_DIR/$ARCH"

# Downloaded on the host since curl breaks in the arm64 container after the libssl workaround
if [ -f "$TARBALL" ] && echo "$FLUENTBIT_SHA256  $TARBALL" | sha256sum --check --status; then
    echo "Using already downloaded $TARBALL"
else
    echo "Downloading Fluent Bit $FLUENTBIT_COMMIT"
    curl -fsSL -o "$TARBALL" "https://github.com/fluent/fluent-bit/archive/$FLUENTBIT_COMMIT.tar.gz"
    echo "$FLUENTBIT_SHA256  $TARBALL" | sha256sum --check
fi

"build_${ARCH}"

BINARY_CLASS=$(readelf -h "$BINARY" | sed -n 's/^ *Class: *//p')
BINARY_MACHINE=$(readelf -h "$BINARY" | sed -n 's/^ *Machine: *//p')
if [ "$BINARY_CLASS" != "$ELF_CLASS" ] || [ "$BINARY_MACHINE" != "$ELF_MACHINE" ]; then
    echo "$BINARY is $BINARY_CLASS $BINARY_MACHINE but $ARCH needs $ELF_CLASS $ELF_MACHINE" >&2
    exit 1
fi

PACKAGE_DIR=$(mktemp -d)
trap 'rm -rf "$PACKAGE_DIR"' EXIT
# mktemp -d makes it 0700, which would end up on ./ in the deb
chmod 0755 "$PACKAGE_DIR"

install -d -m 0755 "$PACKAGE_DIR/DEBIAN" "$PACKAGE_DIR/usr" "$PACKAGE_DIR/usr/bin"
install -m 0755 "$BINARY" "$PACKAGE_DIR/usr/bin/fluent-bit"
INSTALLED_SIZE=$(du -sk "$PACKAGE_DIR/usr" | cut -f1)

cat << EOF > "$PACKAGE_DIR/DEBIAN/control"
Package: fluentbit
Version: ${FLUENTBIT_VERSION}
Architecture: ${ARCH}
Maintainer: Nureva Inc. <support@nureva.com>
Installed-Size: ${INSTALLED_SIZE}
Section: utils
Priority: optional
Depends: ${DEPENDS}
Description: Fluent Bit log forwarder for Nureva devices
 Standalone ${ARCH^^} Fluent Bit executable.
EOF

dpkg-deb -Z"$COMPRESSION" --root-owner-group --build "$PACKAGE_DIR" "$DEB_FILE"
