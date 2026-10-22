source /ctx/lib/fetch-helpers.sh

fetch_verified "$ASSET_MOONSHINE_URL" "$ASSET_MOONSHINE_SHA256" /tmp/moonshine.rpm
# The pinned sha256 is the verifier; the package is not signed.
dnf install -y --nogpgcheck /tmp/moonshine.rpm
rm -f /tmp/moonshine.rpm
