# Waydroid's images and per-app data live on the games share, so a rebuild
# keeps Android apps and their data.
rm -rf /var/lib/waydroid
ln -s /var/mnt/games/.waydroid /var/lib/waydroid
