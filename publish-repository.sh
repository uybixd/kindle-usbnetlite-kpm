#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KPM_HELPER="${KPM_HELPER:-${PROJECT_ROOT}/../KPM/kpm-helper.py}"
REPOSITORY_MANIFEST="${REPOSITORY_MANIFEST:-${PROJECT_ROOT}/repository/manifest.v2.json}"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/usbnetlite_VERSION_PLATFORM.kpkg" >&2
    exit 1
fi

PACKAGE_PATH="$1"

if [ ! -f "${KPM_HELPER}" ]; then
    echo "Missing kpm-helper.py: ${KPM_HELPER}" >&2
    echo "Set KPM_HELPER to the helper from https://github.com/KindleModding/KPM" >&2
    exit 1
fi
if [ ! -f "${REPOSITORY_MANIFEST}" ]; then
    echo "Missing repository manifest: ${REPOSITORY_MANIFEST}" >&2
    exit 1
fi
if [ ! -f "${PACKAGE_PATH}" ]; then
    echo "Missing KPM package: ${PACKAGE_PATH}" >&2
    exit 1
fi

python3 "${KPM_HELPER}" repo add "${REPOSITORY_MANIFEST}" "${PACKAGE_PATH}"

# kpm-helper writes compact JSON. Pretty-print it to keep repository updates
# reviewable in Git without changing its contents.
FORMATTED_MANIFEST="${REPOSITORY_MANIFEST}.formatted"
python3 -m json.tool "${REPOSITORY_MANIFEST}" > "${FORMATTED_MANIFEST}"
mv -f "${FORMATTED_MANIFEST}" "${REPOSITORY_MANIFEST}"

echo "Repository updated: ${REPOSITORY_MANIFEST}"
echo "Commit and publish the repository directory over HTTPS before users run kpm add-repo."
