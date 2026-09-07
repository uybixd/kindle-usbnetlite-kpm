#!/bin/sh

RUNTIME_DIR="${USBNETLITE_DEST:-/mnt/us/usbnetlite}"
KUAL_DIR="${USBNETLITE_KUAL_DEST:-/mnt/us/extensions/usbnetlite}"
SSH_PID="${RUNTIME_DIR}/run/sshd.pid"
UPGRADE_MARKER="${RUNTIME_DIR}/run/kpm-upgrade-pending"

# Stop USB networking before replacing or removing its binaries. Failure is
# non-fatal so that a damaged installation can still be uninstalled.
if [ -f "${RUNTIME_DIR}/bin/usbnetwork" ] && lsmod 2>/dev/null | grep -q g_ether; then
    sh "${RUNTIME_DIR}/bin/usbnetwork" usbms || true
fi

if [ -f "${SSH_PID}" ]; then
    PID="$(cat "${SSH_PID}" 2>/dev/null || true)"
    if [ -n "${PID}" ] && kill -0 "${PID}" 2>/dev/null; then
        kill -TERM "${PID}" 2>/dev/null || true
    fi
    rm -f "${SSH_PID}"
fi

if [ "${1:-}" = "upgrade" ]; then
    if [ -d "${RUNTIME_DIR}" ]; then
        mkdir -p "${RUNTIME_DIR}/run"
        : > "${UPGRADE_MARKER}"
    fi
    echo "USBNetLite stopped for upgrade; configuration and SSH keys were preserved."
    exit 0
fi

# KPM calls the new package's normal uninstall hook if an upgrade install
# fails. Preserve the old runtime data in that recovery path.
if [ -f "${UPGRADE_MARKER}" ]; then
    rm -f "${UPGRADE_MARKER}"
    echo "USBNetLite upgrade cleanup preserved configuration and SSH keys."
    exit 0
fi

case "${RUNTIME_DIR}" in
    /|/mnt|/mnt/us|"")
        echo "Refusing to remove unsafe runtime path: ${RUNTIME_DIR}"
        exit 1
        ;;
esac
case "${KUAL_DIR}" in
    /|/mnt|/mnt/us|/mnt/us/extensions|"")
        echo "Refusing to remove unsafe KUAL path: ${KUAL_DIR}"
        exit 1
        ;;
esac

rm -rf "${KUAL_DIR}" "${RUNTIME_DIR}"
echo "USBNetLite files and user configuration were removed."
