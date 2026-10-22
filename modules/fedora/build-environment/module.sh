source /ctx/lib/family.sh
stash_systemctl

# A plain container image installs no documentation: `rockylinux:10` sets
# `tsflags=nodocs`, the rpm twin of Ubuntu's dpkg excludes, and a machine wants
# its man pages. What the base already unpacked stays stripped until it is
# reinstalled. No bootc rpm base carries the line, so they skip all of this.
if grep -qx 'tsflags=nodocs' /etc/dnf/dnf.conf 2> /dev/null; then
    sed -i '/^tsflags=nodocs$/d' /etc/dnf/dnf.conf
    mapfile -t installed < <(rpm -qa --qf '%{NAME}\n' | grep -vx gpg-pubkey)
    dnf -y reinstall "${installed[@]}"
fi

# CentOS Stream 10 ships dnf4 and no dnf5, and COPR is Fedora's.
if command -v dnf5 > /dev/null; then
    dnf5 install -y dnf5-plugins
fi

# Buildah commits this layer with the SQLite rpmdb WAL still open, which
# the next layer's dnf then sees as a malformed database. Force a checkpoint.
dnf5 install -y sqlite
rpm --rebuilddb || true
if ls /usr/share/rpmrebuilddb.* > /dev/null 2>&1; then
    rm -rf /usr/share/rpm
    mv /usr/share/rpmrebuilddb.* /usr/share/rpm
fi

# Again, since both installs above can put the real binary back.
stash_systemctl
