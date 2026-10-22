# EmuDeck's state goes on the games share: the AppImages it downloads, the
# Emulation tree, its settings and backend, and Steam ROM Manager's parsers.
h=/var/home/steam
mkdir -p "$h/.config"
ln -sfn /var/mnt/games/Applications "$h/Applications"
ln -sfn /var/mnt/games/Emulation "$h/Emulation"
ln -sfn /var/mnt/games/.emudeck "$h/.config/EmuDeck"
ln -sfn /var/mnt/games/.steam-rom-manager "$h/.config/steam-rom-manager"
chown -h 1000:1000 "$h/Applications" "$h/Emulation" "$h/.config" \
    "$h/.config/EmuDeck" "$h/.config/steam-rom-manager"
