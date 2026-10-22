# The build's NSS resolves host groups, but useradd reads the image's
# /etc/group. Write the missing groups there directly.
gid=990
for g in render input video audio; do
    grep -q "^${g}:" /etc/group || echo "${g}:x:${gid}:" >> /etc/group
    gid=$((gid + 1))
done

useradd -u 1000 -G wheel,input,video,render,audio -s /bin/bash steam \
    || usermod -aG wheel,input,video,render,audio steam

# No passwords: SSH is key-only and sudo needs none.
passwd -l steam
passwd -l root

install -D -m 0440 /dev/stdin /etc/sudoers.d/steam << 'SUDO'
steam ALL=(ALL) NOPASSWD:ALL
SUDO

mkdir -p /var/home/steam
chown 1000:1000 /var/home/steam
