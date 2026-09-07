#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_SOURCE="${PROJECT_ROOT}/kpm/package"
STAGE_ROOT="${PROJECT_ROOT}/build/kpm-package"
STAGE_DIR="${STAGE_ROOT}/usbnetlite"
OUTPUT_DIR="${PROJECT_ROOT}/out"

KPM_HELPER="${KPM_HELPER:-${PROJECT_ROOT}/../KPM/kpm-helper.py}"
KOX_TOOLCHAIN_ROOT="${KOX_TOOLCHAIN_ROOT:-${PROJECT_ROOT}/../koxtoolchain}"

if [ ! -f "${KPM_HELPER}" ]; then
    echo "Missing kpm-helper.py: ${KPM_HELPER}" >&2
    echo "Set KPM_HELPER to the helper from https://github.com/KindleModding/KPM" >&2
    exit 1
fi
if [ ! -f "${KOX_TOOLCHAIN_ROOT}/refs/x-compile.sh" ]; then
    echo "Missing koxtoolchain: ${KOX_TOOLCHAIN_ROOT}" >&2
    echo "Set KOX_TOOLCHAIN_ROOT to a configured KindleModding/koxtoolchain checkout." >&2
    exit 1
fi

if command -v getconf >/dev/null 2>&1; then
    BUILD_JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
fi
if [ -z "${BUILD_JOBS:-}" ] && command -v sysctl >/dev/null 2>&1; then
    BUILD_JOBS="$(sysctl -n hw.ncpu 2>/dev/null || true)"
fi
BUILD_JOBS="${BUILD_JOBS:-1}"

git -C "${PROJECT_ROOT}" submodule update --init dropbear openssh

# The existing binaries and patches target Kindle armhf devices.
# shellcheck disable=SC1091
. "${KOX_TOOLCHAIN_ROOT}/refs/x-compile.sh" khf env
make -C "${PROJECT_ROOT}" -j"${BUILD_JOBS}" kpm-binaries

case "${STAGE_ROOT}" in
    "${PROJECT_ROOT}/build/"*) ;;
    *)
        echo "Unsafe staging path: ${STAGE_ROOT}" >&2
        exit 1
        ;;
esac

rm -rf "${STAGE_ROOT}"
mkdir -p "${STAGE_DIR}/payload" "${OUTPUT_DIR}"
cp -R "${PACKAGE_SOURCE}/." "${STAGE_DIR}/"
cp -R "${PROJECT_ROOT}/extension/usbnetlite" "${STAGE_DIR}/payload/usbnetlite"
cp -R "${PROJECT_ROOT}/extension/extensions" "${STAGE_DIR}/payload/extensions"
cp -f "${PROJECT_ROOT}/build/dropbearmulti" "${STAGE_DIR}/payload/usbnetlite/bin/dropbearmulti"
cp -f "${PROJECT_ROOT}/build/sftp-server" "${STAGE_DIR}/payload/usbnetlite/bin/sftp-server"

PACKAGE_VERSION="$(python3 -c 'import json, sys; print(".".join(map(str, json.load(open(sys.argv[1]))["version"])))' "${STAGE_DIR}/manifest.json")"
printf 'USBNetLite %s (KPM)\n' "${PACKAGE_VERSION}" > "${STAGE_DIR}/payload/usbnetlite/etc/VERSION"

chmod 0755 \
    "${STAGE_DIR}/install.sh" \
    "${STAGE_DIR}/launch.sh" \
    "${STAGE_DIR}/uninstall.sh" \
    "${STAGE_DIR}/payload/extensions/usbnetlite/bin/usbnetlite.sh" \
    "${STAGE_DIR}/payload/usbnetlite/bin/dropbearmulti" \
    "${STAGE_DIR}/payload/usbnetlite/bin/libkh5" \
    "${STAGE_DIR}/payload/usbnetlite/bin/sftp-server" \
    "${STAGE_DIR}/payload/usbnetlite/bin/usbnetwork" \
    "${STAGE_DIR}/payload/usbnetlite/bin/usbnetlite.sh"

python3 "${KPM_HELPER}" package pack "${STAGE_DIR}" "${OUTPUT_DIR}"
