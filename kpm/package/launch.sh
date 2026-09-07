#!/bin/sh

RUNTIME_DIR="${USBNETLITE_DEST:-/mnt/us/usbnetlite}"
CONTROLLER="${RUNTIME_DIR}/bin/usbnetlite.sh"

if [ ! -f "${CONTROLLER}" ]; then
    echo "USBNetLite is not installed correctly: ${CONTROLLER} is missing."
    exit 1
fi

case "${1:-toggle}" in
    toggle|toggle_usbnet)
        ACTION="toggle_usbnet"
        ;;
    start|start_usbnet)
        ACTION="start_usbnet"
        ;;
    stop|stop_usbnet)
        ACTION="stop_usbnet"
        ;;
    status|usbnet_status)
        ACTION="usbnet_status"
        ;;
    enable-wifi|enable_wifi)
        ACTION="enable_wifi"
        ;;
    disable-wifi|disable_wifi)
        ACTION="disable_wifi"
        ;;
    restore-config|restore_config)
        ACTION="restore_config"
        ;;
    version|show_version)
        ACTION="show_version"
        ;;
    *)
        echo "Usage: kpm launch usbnetlite [start|stop|toggle|status|enable-wifi|disable-wifi|restore-config|version]"
        exit 1
        ;;
esac

exec sh "${CONTROLLER}" "${ACTION}"
