#!/bin/bash
# Put the VM on the LAN: a bridge over the wired NIC, plus a
# persistent tap the VM attaches to. NetworkManager owns all three, so they
# survive reboots. The bridge takes the NIC's MAC, so the host keeps its
# DHCP lease; the guest gets its own lease from the LAN's DHCP server.
#
#   sudo host/setup-network.sh [TAP_OWNER_UID]
#
# Reads NIC, BRIDGE and TAP from host/steam-bootc.conf. Idempotent. Rolls back
# to the NIC's old profile if the bridge gets no address. The NIC must not
# carry a macvlan or ipvlan (podman's macvlan networks included): those hold
# it, and the kernel refuses to bridge it (EBUSY).
set -euo pipefail
[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"

. "$(dirname "$(readlink -f "$0")")/config.sh"

have() { nmcli -t -f NAME c show | grep -qx "$1"; }

port=$BRIDGE-port
nic=$NIC
if [ -z "$nic" ] && have "$port"; then
    nic=$(nmcli -g connection.interface-name c show "$port")
fi
if [ -z "$nic" ]; then
    nic=$(ip -o route show default | awk '$5 !~ /^(br|wl|tailscale|virbr|podman|docker)/ {print $5; exit}')
fi
[ -n "$nic" ] || {
    echo "no wired NIC with a default route; set NIC in host/steam-bootc.conf" >&2
    exit 1
}
owner=${1:-${SUDO_UID:-1000}}
mac=$(cat "/sys/class/net/$nic/address")
old=$(nmcli -g GENERAL.CONNECTION device show "$nic")

have "$BRIDGE" || nmcli c add type bridge con-name "$BRIDGE" ifname "$BRIDGE" \
    bridge.stp no bridge.mac-address "$mac" \
    ipv4.method auto ipv6.method auto connection.autoconnect yes
have "$port" || nmcli c add type ethernet con-name "$port" ifname "$nic" \
    slave-type bridge master "$BRIDGE" connection.autoconnect yes
have "$TAP" || nmcli c add type tun con-name "$TAP" ifname "$TAP" \
    tun.mode tap tun.owner "$owner" tun.multi-queue no tun.vnet-hdr no \
    slave-type bridge master "$BRIDGE" connection.autoconnect yes

case "$old" in '' | "$port") old="" ;; *) nmcli c modify "$old" connection.autoconnect no ;; esac
nmcli c modify "$port" connection.autoconnect yes
# Failures here fall through to the address check, which rolls back.
nmcli c up "$BRIDGE" || true
nmcli c up "$port" || true
nmcli c up "$TAP" || true

for _ in $(seq 30); do
    ip -4 -o addr show "$BRIDGE" | grep -q inet && break
    sleep 1
done
if ! ip -4 -o addr show "$BRIDGE" | grep -q inet; then
    echo "$BRIDGE got no IPv4 address; restoring ${old:-the previous profile} on $nic" >&2
    nmcli c modify "$port" connection.autoconnect no
    nmcli c down "$BRIDGE" || true
    if [ -n "$old" ]; then
        nmcli c modify "$old" connection.autoconnect yes
        nmcli c up "$old"
    fi
    exit 1
fi
ip -br addr show "$BRIDGE"
ip -br link show "$TAP"
