source /ctx/lib/fetch-helpers.sh

fetch_verified "$ASSET_RELAY_URL" "$ASSET_RELAY_SHA256" /tmp/xone-relay
install -D -m 0755 /tmp/xone-relay /usr/lib/xone-relay/xone-relay
rm -f /tmp/xone-relay
