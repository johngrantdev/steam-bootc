source /ctx/lib/fetch-helpers.sh

fetch_verified "$ASSET_DECKY_URL" "$ASSET_DECKY_SHA256" /tmp/PluginLoader
install -D -m 0755 /tmp/PluginLoader /usr/lib/decky-loader/PluginLoader
printf 'v%s\n' "$ASSET_DECKY_VERSION" > /usr/lib/decky-loader/version
rm -f /tmp/PluginLoader
