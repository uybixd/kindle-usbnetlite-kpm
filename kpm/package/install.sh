#!/bin/sh

set -e

RUNTIME_DIR="${USBNETLITE_DEST:-/mnt/us/usbnetlite}"
KUAL_DIR="${USBNETLITE_KUAL_DEST:-/mnt/us/extensions/usbnetlite}"
UPGRADE_MARKER="${RUNTIME_DIR}/run/kpm-upgrade-pending"
PAYLOAD_DIR="./payload/usbnetlite"
KUAL_PAYLOAD_DIR="./payload/extensions/usbnetlite"

for legacy_file in /etc/upstart/usbnetlite.conf /etc/upstart/usbnetlite-preinit.conf; do
    if [ -e "${legacy_file}" ]; then
        echo "Legacy USBNetLite Upstart integration detected at ${legacy_file}."
        echo "Remove the old MRPI installation before installing the pure KPM package."
        exit 1
    fi
done

if [ ! -f "${PAYLOAD_DIR}/bin/dropbearmulti" ] || [ ! -f "${PAYLOAD_DIR}/bin/sftp-server" ]; then
    echo "USBNetLite payload is incomplete: Dropbear or sftp-server is missing."
    exit 1
fi

echo "Installing USBNetLite into ${RUNTIME_DIR}"
mkdir -p "${RUNTIME_DIR}/bin" "${RUNTIME_DIR}/etc/dropbear" "${RUNTIME_DIR}/run"

# These files are owned by the package and are refreshed on every upgrade.
for runtime_file in dropbearmulti libkh5 sftp-server usbnetwork usbnetlite.sh; do
    cp -f "${PAYLOAD_DIR}/bin/${runtime_file}" "${RUNTIME_DIR}/bin/${runtime_file}"
done
chmod 0755 \
    "${RUNTIME_DIR}/bin/dropbearmulti" \
    "${RUNTIME_DIR}/bin/libkh5" \
    "${RUNTIME_DIR}/bin/sftp-server" \
    "${RUNTIME_DIR}/bin/usbnetwork" \
    "${RUNTIME_DIR}/bin/usbnetlite.sh"

cp -f "${PAYLOAD_DIR}/etc/VERSION" "${RUNTIME_DIR}/etc/VERSION"
cp -f "${PAYLOAD_DIR}/etc/config" "${RUNTIME_DIR}/etc/config.default"

# User settings, authorized keys, and generated host keys survive upgrades.
if [ ! -f "${RUNTIME_DIR}/etc/config" ]; then
    cp -f "${PAYLOAD_DIR}/etc/config" "${RUNTIME_DIR}/etc/config"
fi
if [ ! -f "${RUNTIME_DIR}/etc/dropbear/authorized_keys" ]; then
    cp -f "${PAYLOAD_DIR}/etc/dropbear/authorized_keys" "${RUNTIME_DIR}/etc/dropbear/authorized_keys"
fi

echo "Installing KUAL menu into ${KUAL_DIR}"
mkdir -p "${KUAL_DIR}/bin"
cp -f "${KUAL_PAYLOAD_DIR}/config.xml" "${KUAL_DIR}/config.xml"
cp -f "${KUAL_PAYLOAD_DIR}/menu.json" "${KUAL_DIR}/menu.json"
cp -f "${KUAL_PAYLOAD_DIR}/bin/usbnetlite.sh" "${KUAL_DIR}/bin/usbnetlite.sh"
chmod 0755 "${KUAL_DIR}/bin/usbnetlite.sh"

# The previous version leaves this marker before a KPM upgrade. Remove it only
# after the new payload and KUAL entry point have both been installed.
rm -f "${UPGRADE_MARKER}"

if [ "${1:-}" = "upgrade" ]; then
    echo "USBNetLite upgraded; existing configuration and SSH keys were preserved."
else
    echo "USBNetLite installed. It will not start automatically at boot."
fi

echo "Default Wi-Fi SSH login: root / kindle"
echo "WARNING: Change the public default password before using SSH on an untrusted network."
echo "Edit ${RUNTIME_DIR}/etc/config to change the password, then restart USBNetLite."
