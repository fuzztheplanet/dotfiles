#!/bin/sh

### Simple wrapper script around wpa_supplicant and dhcpcd

CONF_DIR=${CONF_DIR:="/etc/wpa_supplicant"}

usage() {

    echo "USAGE: $0 [-l,--list] conf_file interface"
    echo "  conf_file     wpa_supplicant conf file"
    echo "  interface     network interface name"
    echo "  -l, --list    List avalaible files in \${CONF_DIR}"
    echo "                Default is: ${CONF_DIR}"
    echo "                To change it edit this file or use:"
    echo "                CONF_DIR=path/to/dir $0 conf_file interface"
    echo "  -h, --help    Show this help message"
    echo
}


list() {

    echo "Configuration files in ${CONF_DIR}:"
    find "${CONF_DIR}"/* -exec basename {} \; | xargs -I{} echo "  - {}"
    echo

    echo "Interfaces:"
    find "/sys/class/net"/* -exec basename {} \; | xargs -I{} echo "  - {}"
    echo
}


[ "$1" = "-h" ] || [ "$1" = "--help" ] && usage && exit 0
[ "$1" = "-l" ] || [ "$1" = "--list" ] && list && exit 0
[ ! $# -eq 2 ] && usage && exit 0

sudo wpa_supplicant -B -i "$2" -c "${CONF_DIR}/$1"
sleep 2
sudo dhcpcd "$2"
