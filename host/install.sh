#!/bin/bash
# Install the VM on a host that ships nesbox@.service and
# nvgpu@.service: LAN bridge and tap, the nesbox config, and boot-time start.
#
#   host/build-rootfs.sh        # first, as the user
#   sudo host/install.sh        # then this
#   sudo systemctl start nesbox@NAME    (NAME from host/steam-bootc.conf)
#
# Settings come from host/steam-bootc.conf (sudo drops the environment, so use
# the file). Run from the user's sudo: the disk, kernel and games share are
# that user's, and $HOME in the config is theirs.
set -euo pipefail
[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"

user=${SUDO_USER:?run with sudo from the user who built the rootfs}
HOME=$(getent passwd "$user" | cut -d: -f6)
uid=$(id -u "$user")
here=$(dirname "$(readlink -f "$0")")
. "$here/config.sh"

[ -f "$OUT/rootfs.ext4" ] && [ -f "$OUT/vmlinux" ] \
    || {
        echo "no rootfs in $OUT; run host/build-rootfs.sh first" >&2
        exit 1
    }
install -d -o "$user" -g "$user" "$GAMES"
# Optional: the share at the path the VM mounts it, so the absolute paths
# Steam and EmuDeck record there resolve on the host too.
if [ -n "$HOST_LINK" ] && { [ ! -e "$HOST_LINK" ] || [ -L "$HOST_LINK" ]; }; then
    ln -sfn "$GAMES" "$HOST_LINK"
fi

"$here/setup-network.sh" "$uid"

# selinux=0: the flattened rootfs carries no SELinux labels.
# No vram-limit-mib here: the backend's NVGPU_VRAM_LIMIT_MIB is the cap, and
# nesbox refuses a guest whose value disagrees with it.
install -d /etc/nesbox
cat > "/etc/nesbox/${NAME}.json" << JSON
{
  "boot-source": {
    "kernel_image_path": "$OUT/vmlinux",
    "boot_args": "console=hvc0 root=/dev/vda rw selinux=0 quiet"
  },
  "drives": [
    { "drive_id": "rootfs", "path_on_host": "$OUT/rootfs.ext4", "is_root_device": true, "is_read_only": false }
  ],
  "machine-config": { "vcpu_count": $VCPUS, "mem_size_mib": $MEM_MIB },
  "gpu-forward": { "socket": "/run/nvgpu/$NAME.sock" },
  "network": { "tap-name": "$TAP", "mac": "$MAC" },
  "shared-directories": [
    { "tag": "games", "path-on-host": "$GAMES", "read-only": false, "guest-owner": [1000, 1000] }
  ]
}
JSON

# nesbox opens the tap but never creates it, and nesbox@ does not restart.
# Wait for NetworkManager's tap rather than failing at boot.
install -d "/etc/systemd/system/nesbox@${NAME}.service.d"
cat > "/etc/systemd/system/nesbox@${NAME}.service.d/10-tap.conf" << UNIT
[Unit]
Requires=sys-subsystem-net-devices-$TAP.device
After=sys-subsystem-net-devices-$TAP.device
UNIT

# A Steam Link or Steam client on the host itself finds the VM by broadcast,
# and the VM's unicast answer is not traffic firewalld tracks; without the
# service the answer is dropped. LAN clients reach the VM over the bridge,
# which the host's firewall does not filter.
if systemctl is-active -q firewalld; then
    zone=$(firewall-cmd --get-zone-of-interface="$BRIDGE" 2> /dev/null || firewall-cmd --get-default-zone)
    firewall-cmd -q --permanent --zone="$zone" --add-service=steam-streaming
    firewall-cmd -q --reload
fi

systemctl daemon-reload
systemctl enable "nesbox@${NAME}.service"
echo "installed; start it with: sudo systemctl start nesbox@${NAME}"
