# Paired clients (~/.local/share/moonshine/state.toml) live on the games
# share beside the certificate, so a rebuild keeps the pairing.
mkdir -p /var/home/steam/.local/share
ln -sfn /var/mnt/games/.moonshine /var/home/steam/.local/share/moonshine
chown -h 1000:1000 /var/home/steam/.local/share /var/home/steam/.local/share/moonshine

# The instance its preset names (see 50-moonshine.preset).
systemctl enable moonshine@steam.service
