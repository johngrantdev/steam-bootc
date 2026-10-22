### virtio_gpu_nv, built against the image kernel

source /usr/libexec/kernel-devel-helpers.sh

tools=()
for p in gcc make elfutils-libelf-devel; do
    rpm -q "$p" > /dev/null || tools+=("$p")
done
kernel_devel_install "${tools[@]}"

KVER=$(kver)
SRC=/tmp/virtio-nvgpu
rm -rf "$SRC"
cp -a "$MODDIR/driver" "$SRC"
make -C "/usr/src/kernels/$KVER" M="$SRC" CONFIG_VIRTIO_GPU_NV=m modules

install -D -m 0644 "$SRC/virtio_gpu_nv.ko" \
    "/usr/lib/modules/$KVER/extra/virtio_gpu_nv.ko"
depmod -a "$KVER"

mkdir -p /usr/lib/virtio-nvgpu
touch /usr/lib/virtio-nvgpu/installed

rm -rf "$SRC"
kernel_devel_remove "${tools[@]}"

# NVIDIA's udev rule runs nvidia-modprobe for the nvidia driver's devices.
# virtio_gpu_nv's nodes take their mode from 99-virtio-nvgpu.rules instead.
rm -f /usr/lib/udev/rules.d/60-nvidia.rules
