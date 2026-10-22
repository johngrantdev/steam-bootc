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
src=/tmp/virtio-nvgpu
fetch_extract "$ASSET_VIRTIO_NVGPU_URL" "$ASSET_VIRTIO_NVGPU_SHA256" "$src" --strip-components=1
# A 4 GiB shared window, small zones first. The tag's 1 GiB window gives
# write-combine 768 MiB, which one current game behind a nested compositor
# fills; and its write-back zone sits past 2 GiB once the window grows,
# where a 32-bit guest process's mmap() cannot reach. nesbox's window BAR
# must match (host-modules/nesbox). Drop both when upstream sizes the
# window per guest.
git -C "$src" apply "$MODDIR/virtio-nvgpu-window-4gib.patch"
(cd "$src" && cargo build --release --locked --features vhost-user -p device --bin vhost-user-nvgpu)
install -D -m 0755 "$src/target/release/vhost-user-nvgpu" /usr/libexec/nvgpu/vhost-user-nvgpu
rm -rf "$src"

[ ${#missing[@]} -eq 0 ] || dnf5 remove -y --noautoremove "${missing[@]}"
