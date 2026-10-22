### Proton-CachyOS, for Steam's system-wide compatibility tool search path

source /ctx/lib/fetch-helpers.sh

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fetch_extract "$ASSET_PROTON_URL" "$ASSET_PROTON_SHA256" "$TMP"

install -d -m 0755 /usr/share/steam/compatibilitytools.d
rm -rf /usr/share/steam/compatibilitytools.d/proton-cachyos
mv "$TMP"/proton-cachyos-*/ /usr/share/steam/compatibilitytools.d/proton-cachyos
# The tarball's owners are not meaningful in the image.
chown -R root:root /usr/share/steam/compatibilitytools.d/proton-cachyos
