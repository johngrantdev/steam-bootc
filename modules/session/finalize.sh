# Steam's root, the client and its library, lives on the games share, so
# rebuilding the image loses nothing. The link dangles until the share
# mounts. /var/mnt/games itself is not created here: the image's /var
# becomes tmpfiles rules, and a rule owning the mountpoint would chown the
# share's root at every boot, which nesbox then maps the guest's user onto.
mkdir -p /var/home/steam/.local/share
ln -sfn /var/mnt/games/Steam /var/home/steam/.local/share/Steam
# Steam keeps its OOBE completion, language and region in ~/.steam/registry.vdf.
# That directory otherwise lives only in the rebuilt rootfs, so Steam repeats
# first-run setup after every image update. Keep it on the games share.
ln -sfn /var/mnt/games/.steam /var/home/steam/.steam
chown -R -h 1000:1000 /var/home/steam
