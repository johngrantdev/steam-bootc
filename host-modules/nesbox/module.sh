source /ctx/lib/fetch-helpers.sh

# Build tools this module installs are removed again; ones the image
# already had stay.
missing=()
for p in cargo rust git-core; do
    rpm -q "$p" > /dev/null || missing+=("$p")
done
[ ${#missing[@]} -eq 0 ] || dnf5 install -y "${missing[@]}"

# /root is a dangling link to /var/roothome while an image builds; keep
# cargo's home on the layer's tmpfs.
export CARGO_HOME=/tmp/cargo
src=/tmp/nesbox
fetch_extract "$ASSET_NESBOX_URL" "$ASSET_NESBOX_SHA256" "$src" --strip-components=1
# Built without virgl: the host forwards NVIDIA ioctls and must not link
# virglrenderer or Mesa. v0.3.1 gates the stats surface behind virgl
# everywhere but the module declaration; this makes that build compile.
git -C "$src" apply "$MODDIR/nesbox-no-virgl-stats.patch"
# The GPU window BAR is 4 GiB, matching host-modules/virtio-nvgpu's backend
# zones; the two must agree or the guest cannot map.
git -C "$src" apply "$MODDIR/nesbox-window-4gib.patch"
# No --locked: the tag's Cargo.lock still names the previous workspace
# version, and Cargo updates that one entry from the lock.
(cd "$src" && cargo build --release --no-default-features -p nesbox-vmm --bin nesbox)
install -D -m 0755 "$src/target/release/nesbox" /usr/libexec/nvgpu/nesbox
rm -rf "$src"

[ ${#missing[@]} -eq 0 ] || dnf5 remove -y --noautoremove "${missing[@]}"
