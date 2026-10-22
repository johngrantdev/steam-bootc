# ~/homebrew lives on the games share, beside Steam and Moonshine's state.
ln -sfn /var/mnt/games/.decky /var/home/steam/homebrew
chown -h 1000:1000 /var/home/steam/homebrew
# The steam user's Flatpak installation and app data (Edge's profile holds store
# logins) go on the share too. Flatpak's user repo works there without
# xattrs, which nesbox's virtiofsd does not enable.
mkdir -p /var/home/steam/.local/share
ln -sfn /var/mnt/games/.flatpak /var/home/steam/.local/share/flatpak
ln -sfn /var/mnt/games/.var /var/home/steam/.var
chown -h 1000:1000 /var/home/steam/.local/share/flatpak /var/home/steam/.var
# Unifideck keeps store tokens in ~/.config. Persist those, but leave its
# Edge auth profile in the local rootfs: a Chromium profile on virtiofs
# breaks input and fullscreen behaviour.
mkdir -p /var/home/steam/.config
ln -sfn /var/mnt/games/.unifideck-config /var/home/steam/.config/unifideck
ln -sfn /var/mnt/games/.legendary /var/home/steam/.config/legendary
chown -h 1000:1000 /var/home/steam/.config/unifideck /var/home/steam/.config/legendary
