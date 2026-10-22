#!/bin/bash
# Turn the built steam-microvm-nvidia container image into what nesbox boots: a flat ext4
# rootfs and the image's own kernel as a PVH vmlinux. nesbox loads no initrd
# and no bootloader, so the image is not booted as a bootc deployment; the
# Fedora kernel has virtio-blk, virtio-pci and ext4 built in, which is all
# the root mount needs. State lives on the games share, so a rebuild loses
# nothing.
#
#   host/build-rootfs.sh            (rootless; run as the user who built the image)
#
# Reads NAME, IMAGE, OUT, SIZE and KEYS from host/steam-bootc.conf (see
# steam-bootc.conf.example). The VM always gets its own SSH key,
# $OUT/id_ed25519, generated on first use. Its SSH host keys are kept in
# $OUT/host_keys and injected into the rootfs, so a rebuild does not change
# the identity clients pinned in known_hosts.
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/config.sh"

die() {
    echo "build-rootfs: $*" >&2
    exit 1
}

if systemctl is-active -q "nesbox@${NAME}" 2> /dev/null; then
    die "the VM is running; stop it first: sudo systemctl stop nesbox@${NAME}"
fi
podman image exists "$IMAGE" || die "no image $IMAGE; build it with generated/scripts/tect.sh build"

# The guest's NVIDIA userspace talks to the host's kernel driver, which refuses
# any other release. A mismatch boots, then fails in every GPU client.
host_nv=$(cat /sys/module/nvidia/version 2> /dev/null) \
    || die "no nvidia kernel driver loaded on this host"
image_nv=$(podman run --rm --network none "$IMAGE" \
    rpm -q --qf '%{VERSION}' nvidia-driver-libs.x86_64) \
    || die "$IMAGE has no nvidia-driver-libs"
[ "$host_nv" = "$image_nv" ] \
    || die "$IMAGE has NVIDIA $image_nv, the host driver is $host_nv; set hardware/nvidia's version to $host_nv in steam-bootc.image.kdl and rebuild"

mkdir -p "$OUT"
# A key of the VM's own, so no personal key is ever authorized in it.
[ -f "$OUT/id_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -C "$NAME" -f "$OUT/id_ed25519"

# The guest's host keys live outside the rootfs, so a rebuild keeps the
# identity clients pinned in known_hosts. Delete this directory to rotate.
hostkeys="$OUT/host_keys"
mkdir -p "$hostkeys"
chmod 700 "$hostkeys"
for type in ed25519 ecdsa rsa; do
    [ -f "$hostkeys/ssh_host_${type}_key" ] \
        || ssh-keygen -q -t "$type" -N '' -C "$NAME" -f "$hostkeys/ssh_host_${type}_key"
done
tmp=$(mktemp -d "$OUT/.build.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# Inside the user namespace the image's files appear with their real owners,
# so mkfs copies uid, gid, mode and setuid bits as built.
truncate -s "$SIZE" "$tmp/rootfs.ext4"
podman unshare sh -euc '
    mnt=$(podman image mount "$1")
    trap "podman image unmount \"$1\" > /dev/null" EXIT
    cp "$mnt"/usr/lib/modules/*/vmlinuz "$2/vmlinuz"
    mkfs.ext4 -q -F -L steam-root -d "$mnt" "$2/rootfs.ext4"
' sh "$IMAGE" "$tmp"

# vmlinuz is a bzImage around a zstd-compressed ELF; nesbox wants the ELF.
off=$(python3 -c 'import sys; print(open(sys.argv[1], "rb").read().find(b"\x28\xb5\x2f\xfd"))' "$tmp/vmlinuz")
[ "$off" -ge 0 ] || die "no zstd payload in vmlinuz"
tail -c +$((off + 1)) "$tmp/vmlinuz" | zstd -dcq > "$tmp/vmlinux" 2> /dev/null || true
readelf -n "$tmp/vmlinux" 2> /dev/null | grep -q 'Unknown note type: (0x00000012)' \
    || die "extracted kernel has no PVH entry note"

# The steam user's home comes from tmpfiles at boot; create the path to .ssh now.
{
    cat "$OUT/id_ed25519.pub"
    [ -z "$KEYS" ] || printf '%s\n' "$KEYS"
} > "$tmp/authorized_keys"
{
    for d in /var/home/steam /var/home/steam/.ssh; do
        echo "mkdir $d"
        echo "sif $d uid 1000"
        echo "sif $d gid 1000"
        echo "sif $d mode 040700"
    done
    echo "write $tmp/authorized_keys /var/home/steam/.ssh/authorized_keys"
    echo "sif /var/home/steam/.ssh/authorized_keys uid 1000"
    echo "sif /var/home/steam/.ssh/authorized_keys gid 1000"
    echo "sif /var/home/steam/.ssh/authorized_keys mode 0100600"
} | debugfs -w -f - "$tmp/rootfs.ext4" > /dev/null 2>&1
debugfs -R 'stat /var/home/steam/.ssh/authorized_keys' "$tmp/rootfs.ext4" 2> /dev/null \
    | grep -q 'User:  1000' || die "could not install authorized_keys"

# Put the stable host keys where sshd expects them. The image has none, and
# sshd's key generator skips any type that already exists.
{
    for file in "$hostkeys"/ssh_host_*; do
        echo "rm /etc/ssh/$(basename "$file")"
    done
    for file in "$hostkeys"/ssh_host_*; do
        target="/etc/ssh/$(basename "$file")"
        echo "write $file $target"
        echo "sif $target uid 0"
        echo "sif $target gid 0"
        case "$file" in
            *.pub) echo "sif $target mode 0100644" ;;
            *) echo "sif $target mode 0100600" ;;
        esac
    done
} | debugfs -w -f - "$tmp/rootfs.ext4" > /dev/null 2>&1
debugfs -R 'stat /etc/ssh/ssh_host_ed25519_key' "$tmp/rootfs.ext4" 2> /dev/null \
    | grep -q 'User:  0' || die "could not install SSH host keys"

mv "$tmp/rootfs.ext4" "$OUT/rootfs.ext4"
mv "$tmp/vmlinux" "$OUT/vmlinux"
echo "built $OUT/rootfs.ext4 and $OUT/vmlinux from $IMAGE"
