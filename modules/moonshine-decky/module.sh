source /ctx/lib/fetch-helpers.sh

# The ZIP's root is moonshine-decky/. The seed step in
# modules/decky-loader/files/usr/libexec/steam-session/decky-start installs it
# into ~/homebrew/plugins on the games share.
fetch_extract "$ASSET_MOONSHINE_DECKY_URL" "$ASSET_MOONSHINE_DECKY_SHA256" \
    /usr/share/decky-plugins
# The version decky-start compares to decide whether a seeded copy is stale.
printf '%s\n' "$ASSET_MOONSHINE_DECKY_VERSION" \
    > /usr/share/decky-plugins/moonshine-decky/.seed-version
