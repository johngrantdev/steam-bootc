# steam-bootc

Steam game mode images built on Fedora 44 with bootc, streamed to Moonlight.

## Images
- steam-microvm-nvidia
- steam-bootc-nvidia (planned)

## Features
- Steam game mode (SteamOS mode), one Moonlight app per session
- Game streaming with [Moonshine](https://github.com/hgaiser/moonshine) to
  Moonlight, including 10-bit HDR10 for HDR games, with no display or dummy
  plug
- bootc-built images, rebuilt and replaced by the host
- Proton-CachyOS available to every Steam game's Compatibility settings
- Xbox controllers through a local Xbox Wireless Adapter on the Proxmox host and a
  zero-dependency static Rust evdev/uinput relay to the guest
- Nvidia GPU support
- A micro VM image that shares the nvidia GPU with the host with near native GPU performance. No gpu/vgpu passthrough required.
- Game emulation with EmuDeck
- Android games and apps with Waydroid
- Steam game mode integrations with Decky Loader

steam-microvm-nvidia is a game microVM that runs Steam in game mode on the
host's NVIDIA GPU through
[virtio-nvgpu](https://github.com/nestrilabs/virtio-nvgpu), and streams it
with Moonshine to Moonlight. It boots under
[nesbox](https://github.com/nestrilabs/nesbox), takes its own address on the
LAN, and keeps every piece of state (the Steam install, its library,
Moonlight's pairing) on a directory shared from the host, so the VM's disk can
be rebuilt at will.

```
host                                          guest (this image)
────                                          ──────────────────
NVIDIA driver                                 virtio_gpu_nv.ko  +  matching NVIDIA userspace
nvgpu@steam-microvm-nvidia  (backend)  ◄────► /dev/nvidia*, renderD128
nesbox@steam-microvm-nvidia (the VMM)         moonshine@steam (system unit, user steam):
  vmlinux + rootfs.ext4                         per Moonlight session, a headless compositor
  virtiofs $GAMES → /var/mnt/games              (Xwayland) running one app in steam's
  tap $TAP on bridge $BRIDGE ──── LAN           lingering user manager:
                                                  Steam -steamos3 … -gamepadui, or EmuDeck
                                                frames → Vulkan Video (H.264/HEVC, HDR10)
                                                audio: Moonshine's own PulseAudio server
```

Moonlight's app list comes from the `.desktop` files in
`/usr/share/steam-session/apps`: Steam (the session module) and EmuDeck (the
emudeck module). Starting one starts the app; quitting it in Moonlight stops
it. Nothing runs between sessions but Moonshine and Decky. Waydroid is launched
inside Steam Game Mode as a non-Steam shortcut.

The image is built with [tectonic](https://github.com/tectonic-os/tectonic);
`generated/scripts/tect.sh` fetches the pinned release, so nothing needs
installing for the build beyond podman.

## Requirements

On the host:

- An NVIDIA GPU and driver, with the virtio-nvgpu backend installed as
  `nvgpu@.service` and nesbox as `nesbox@.service`.
  [host-modules/](host-modules) has both as tectonic modules for a bootc
  host image. They need the host's NVIDIA kernel driver (`nvidia-kmod`),
  such as the tectonic library's `hardware/nvidia`, pinned to the release
  the guest's userspace matches:

  ```kdl
  // repo.kdl
  sources {
      modules "steam-bootc-host" {
          url "https://github.com/johngrantdev/steam-bootc"
          path "host-modules"
      }
  }
  // the image
  modules {
      source "tectonic-modules" {
          module "hardware/nvidia" {
              version "615.71.09"
          }
      }
      source "steam-bootc-host" {
          module "virtio-nvgpu"
          module "nesbox"
      }
  }
  ```

  Installed another way, two settings matter:
  - **A 4 GiB shared window**, set the same in the backend and in nesbox
    (the patches in `host-modules/`). At 1 GiB the window's write-combine
    zone fills with one game and the session, and the game fails with
    `VK_ERROR_OUT_OF_DEVICE_MEMORY`.
  - **`LimitNOFILE=524288`** on `nvgpu@.service`: the backend holds one
    descriptor per guest open of `/dev/nvidia*`, and at 1024 a game's
    `vkCreateDevice` fails.
- The backend's per-guest VRAM cap, `NVGPU_VRAM_LIMIT_MIB` (default 4096),
  is set in `/etc/nvgpu/backend.env`.
- NetworkManager, and a wired NIC that nothing else holds. A macvlan or
  ipvlan on it (podman macvlan networks included) makes the kernel refuse to
  bridge it with EBUSY.
- Host RAM for the guest (12 GiB by default) plus the backend: nesbox faults
  all guest RAM in at start.
- podman, e2fsprogs (`mkfs.ext4`, `debugfs`), zstd, binutils (`readelf`) and
  python3 for `host/build-rootfs.sh`.

On the client: Moonlight 6.0 or later. The GPU encodes H.264 and HEVC
(Turing has no AV1 encoder); HDR needs an HDR display and Moonlight's HDR
option.

## Configuration

### Host settings

Copy `host/steam-bootc.conf.example` to `host/steam-bootc.conf` and set what
differs from the defaults. The host scripts read it (or the file named by
`STEAM_BOOTC_CONF`); a setting not in the file can also come from the
environment. `install.sh` runs under sudo, which drops the environment, so
use the file for anything it needs.

| setting | default | what it is |
| --- | --- | --- |
| `NAME` | `steam-microvm-nvidia` | the VM's name: `nesbox@NAME`, `/etc/nesbox/NAME.json`, the backend's socket |
| `GAMES` | `~/Games` | host directory shared into the VM; all persistent state lives here |
| `OUT` | `~/.local/share/$NAME` | where the rootfs, kernel and the VM's SSH key go |
| `IMAGE` | `localhost/steam-microvm-nvidia:latest` | container image to flatten |
| `SIZE` | `20G` | rootfs size (sparse) |
| `KEYS` | none | extra SSH public keys for `steam` |
| `VCPUS` | `8` | guest vCPUs |
| `MEM_MIB` | `12288` | guest RAM. At 8 GiB a game's shader compilation got the session OOM-killed |
| `NIC` | the default-route interface | wired NIC to bridge |
| `BRIDGE` | `br0` | bridge (NetworkManager connection) to create or reuse |
| `TAP` | `steamvm0` | tap device the VM attaches to |
| `MAC` | `02:57:56:00:00:01` | guest MAC, fixed so its DHCP lease is stable |
| `HOST_LINK` | off | e.g. `/var/mnt/games`: a host symlink to `GAMES` at the guest's mount path, so paths Steam and EmuDeck record (library folders, ROM shortcuts) resolve on the host too |

### NVIDIA driver version

The guest's NVIDIA userspace must be the **same version as the host
driver**. It comes from the tectonic library's `hardware/nvidia`, installed
from NVIDIA's repository with its kernel modules off (`kernel-modules
#false`), and its `version` is set in
[steam-bootc.image.kdl](steam-bootc.image.kdl) (currently 615.71.09). For
another host driver, set it to `cat /sys/module/nvidia/version` there and
run `generated/scripts/tect.sh generate`. NVIDIA's Fedora repository must
carry that release. The guest driver carries RM control tables for the 535,
580, 595 and 615 branches (`modules/vm/nvidia-guest/driver/rmctrl/`).

### Proton-CachyOS

The image installs Proton-CachyOS under
`/usr/share/steam/compatibilitytools.d/proton-cachyos`, where Steam looks for
compatibility tools. In a game's Properties → Compatibility, choose
**proton-cachyos**. It has no effect until you force it for a game (or set it
as the default for all titles); Steam's per-title choices still apply
otherwise.

The version is pinned in
[modules/proton-cachyos/module.kdl](modules/proton-cachyos/module.kdl); run
`generated/scripts/tect.sh generate` after changing it.

### Xbox controller relay

The relay is a standalone project in the sibling
[`xone-relay`](../xone-relay) checkout: source, CI, the xone
installer, the sender/receiver units, and the static binary build. This
repository only ships the guest-side module, which downloads the pinned
receiver release and installs it with a wrapper, unit and config.

```
controller
  -> Xbox Wireless Adapter on Proxmox
  -> xone -> /dev/input/eventN (Microsoft Xbox Controller)
  -> xone-relay sender -> TCP 47998 -> LAN
  -> xone-relay receiver (guest) -> one uinput controller per slot
  -> Steam
```

The binary is static musl with only `libc`; no Python, `python3-evdev`, async
runtime or libudev is needed at runtime. The Xbox Wireless Adapter stays on Proxmox and the
guest needs neither `xone` nor USB/IP. USB/IP is deliberately not used for
this Xbox Wireless Adapter: its full firmware load does not survive `vhci-hcd`
(`control message failed: -121`).

The relay supports up to eight controllers (slots 0-7) and `FF_RUMBLE`
force feedback. The relay protocol version is carried in the hello message;
update the sender and receiver together.

#### Proxmox host

The host must already run the patched xone driver: the `dlundqvist/xone`
fork at `f2aa9fe` with PR #225, built with DKMS, with the Xbox Wireless
Adapter firmware installed. The sender installer does not install xone.

Download the release archive on Proxmox and install the sender:

```sh
curl -fLO https://github.com/johngrantdev/xone-relay/releases/latest/download/xone-relay-x86_64-linux-musl.tar.gz
curl -fLO https://github.com/johngrantdev/xone-relay/releases/latest/download/xone-relay-x86_64-linux-musl.tar.gz.sha256
sha256sum -c xone-relay-x86_64-linux-musl.tar.gz.sha256
tar xzf xone-relay-x86_64-linux-musl.tar.gz
cd xone-relay
sudo ./install/sender.sh
```

The installer writes `/usr/local/libexec/xone-relay` and
`xone-relay-sender.service`.

The sender discovers controllers by the exact sysfs name
`Microsoft Xbox Controller` (not `eventN`), so it does not open unrelated
evdev nodes. It reads the Xbox Wireless Adapter's controller nodes, assigns slots, and sends
framed `input_event` batches with `TCP_NODELAY`. When a controller sleeps or
disconnects, that slot is removed and the guest destroys its uinput device;
it reappears when the controller reconnects.

Verify on Proxmox:

```sh
lsusb -d 045e:02e6
cat /sys/bus/usb/devices/3-3:1.0/active_clients   # 1 while the controller is on
grep -A6 'Name="Microsoft Xbox Controller"' /proc/bus/input/devices
systemctl status xone-relay-sender
```

The sender now connects out to the guest receiver. Set the receiver address in
the Proxmox host's `/etc/xone-relay.conf`:

```ini
RECEIVER_ADDRESS=192.168.1.46
PORT=47998
```

The guest must allow inbound TCP 47998 from the Proxmox host. Pair the
controller once with the Xbox Wireless Adapter. The fork's
`install/firmware.sh` installs the March 2017 firmware as
`/lib/firmware/xone_dongle_02e6.bin`. Do not set `fw_override`.

#### Guest

The guest image ships the receiver as the `xone-relay` module. At image
build time it downloads the pinned `v0.1.0` release binary and installs a
thin `xone-relay-receiver` wrapper. There are no Python or evdev packages.
The receiver reads
`/etc/steam-session/xone-relay.conf`:

```ini
PORT=47998
```

The receiver listens for the sender. Change `PORT` if needed, then rebuild the
rootfs. `xone-relay-receiver.service` is enabled by preset and runs as
root for `/dev/uinput`. For each controller slot it creates a uinput device
with the source identity and capabilities, including the FF bitmaps. The
receiver handles the guest's uinput force-feedback upload/erase/play requests
and forwards them to the sender, which drives `EVIOCSFF`/`EV_FF` on the
Xbox Wireless Adapter's evdev node. Games see the same Xbox controller identity as before.

Verify in the guest:

```sh
grep -A8 -i xbox /proc/bus/input/devices
sudo evtest                 # pick a Microsoft Xbox Controller
jstest /dev/input/js0       # if jsdev is enabled
journalctl -u xone-relay-receiver
```

Latency is one wired-LAN hop; the single-controller protocol v1
microbenchmark measured:

| stage | p50 | p95 | p99 | max |
| --- | ---: | ---: | ---: | ---: |
| sender read -> send | 8.7 us | 12.4 us | 18.9 us | 29.4 us |
| receiver recv -> write | 4.1 us | 5.5 us | 12.4 us | 18.5 us |

TCP round trip guest <-> Proxmox was p50 98 us, p99 142 us. The current
binary is 500,320 bytes, static-pie.

**Range:** the relay cannot extend RF. The Xbox Wireless Adapter must stay within Xbox
Wireless range of the controller. The Proxmox host is in the linen closet; if
`active_clients` drops or input stalls when the controller is in the living
room, move the Xbox Wireless Adapter closer, not the relay.

#### Update the relay release

The module pins release `v0.1.0` and its SHA-256 in
`modules/xone-relay/module.kdl`. To use a newer release, change the version
and SHA-256 there, then run `generated/scripts/tect.sh generate`.

The guest uinput device keeps the source identity: name
`Microsoft Xbox Controller`, bus `0x0006`, vendor `0x045e`, product `0x0b00`.
The old Python relay source was removed when the relay moved to its own
repository; rollback copies and units remain in
`/root/xone-relay-python-backup/` on both hosts. USB/IP is not a
rollback for this Xbox Wireless Adapter.

### Android games with Waydroid

Waydroid runs Android in a container and is launched inside Steam Game Mode.
Add `/usr/bin/waydroid-launcher` once as a non-Steam game in Steam. The
launcher starts Waydroid in a nested Cage session, waits for Android to start,
and then sends the controller uevents Waydroid needs. Steam Game Mode remains
the only UI.

The Fedora kernel provides the binder support Waydroid needs. The first launch
downloads the Android system and vendor images and can take several minutes.
The Android images and installed apps live in `/var/mnt/games/.waydroid`, so a
rebuild keeps them.

The launcher initializes Waydroid with the GAPPS image, which includes Google
Play services and the Play Store. Change `-s GAPPS` to `-s VANILLA` in
`modules/waydroid/files/usr/bin/waydroid-launcher` if the image should not
include Google apps.

Waydroid expects a pointer or touch input. Steam Input can provide a mouse
pointer, and Android games with controller support use the relayed Xbox
controller directly. Enable Touchscreen Native Support on the Waydroid
shortcut for multi-touch. Touch-only games are awkward on a TV.

## Setting it up

```sh
cp host/steam-bootc.conf.example host/steam-bootc.conf   # optional; edit as needed
generated/scripts/tect.sh build   # the container image, localhost/steam-microvm-nvidia
host/build-rootfs.sh              # as your user: rootfs.ext4 + vmlinux in $OUT
sudo host/install.sh              # bridge + tap, /etc/nesbox/$NAME.json, boot-time start
sudo systemctl start nesbox@steam-microvm-nvidia
```

`install.sh` also adds firewalld's `steam-streaming` service to the bridge's
zone, if firewalld is running, so a client on the host itself can discover
the VM. LAN clients need nothing.

Then:

1. Find the VM: it takes a DHCP lease from the LAN and announces itself over
   mDNS, as `steam-microvm-nvidia.local` and to Moonlight.
2. Pair: select the host in Moonlight, which shows a PIN, then submit it from
   the VM (Moonshine logs the client's `uniqueid` as it waits):

   ```sh
   curl -X POST http://localhost:47989/submit-pin -d "uniqueid=<uniqueid>&pin=<PIN>"
   ```

   or open the `http://<vm>:47989/pin?uniqueid=…` address it logs.
3. Start **Steam**, and log in on the first start if `$GAMES/Steam` had no
   install.
4. Optional: in Steam, Settings → Compatibility → "Enable Steam Play for all
   other titles" (Proton for Windows-only games).

SSH is key-only, with a key generated for the VM:

```sh
ssh -i ~/.local/share/steam-microvm-nvidia/id_ed25519 steam@steam-microvm-nvidia.local
```

## Day to day

- **Rebuild after an image change:** `generated/scripts/tect.sh build`,
  `sudo systemctl stop nesbox@steam-microvm-nvidia`, `host/build-rootfs.sh`,
  `sudo systemctl start nesbox@steam-microvm-nvidia`. Nothing is lost: state
  is on the share. `bootc upgrade` does not apply.
- **What persists where** (all under `$GAMES`): the Steam client, library,
  per-game settings and shader caches in `Steam/`; Steam's OOBE completion,
  language and region in `.steam/`; Moonshine's certificate
  and paired clients in `.moonshine/`; Decky in `.decky/`; Flatpak apps in
  `.flatpak/` and `.var/`; EmuDeck in `Applications/`, `Emulation/`,
  `.emudeck/` and `.steam-rom-manager/`. The rootfs holds nothing that is not
  in the image, except the SSH host keys. `build-rootfs.sh` keeps those in
  `$OUT/host_keys` and injects them into each rootfs, so a rebuild keeps the
  same host key; delete that directory to rotate them.
- **HDR:** the stream is HDR10 while the focused content is HDR and SDR
  otherwise, so the client display switches mode when a game starts or
  leaves. Steam shows no HDR toggle but has HDR on, and Proton games get
  `DXVK_HDR=1`; turn HDR on in the game. HDR is detected for Vulkan
  swapchains through Moonshine's WSI layer (Proton/DXVK games, which run
  under Xwayland).
- **Proton:** Steam runs in SteamOS mode, so it applies Valve's per-title
  compatibility choices as on a Deck. Proton-CachyOS is in the image as
  `proton-cachyos`; other builds (GE-Proton) go in
  `$GAMES/Steam/compatibilitytools.d`.
- **Xbox controllers:** the Xbox Wireless Adapter is local to Proxmox and the standalone
  `xone-relay` sender forwards every matching controller to the
  guest's static receiver, including rumble. `journalctl -u
  xone-relay-sender` on Proxmox and `journalctl -u
  xone-relay-receiver` in the guest show the connection; the guest's
  `/proc/bus/input/devices` shows one uinput controller per slot. Rebuild it
  with `../xone-relay/build.sh` and copy the binary as described in the
  relay section.
- **EmuDeck** is its own Moonlight app. Quit Steam first (Steam's Switch to
  Desktop exits it); Steam ROM Manager needs Steam stopped. Choose internal
  storage in EmuDeck, and copy ROMs to `$GAMES/Emulation/roms/<system>` from
  the host.
- **Decky Loader** is in the Quick Access menu. Files it writes on the share
  are root-owned on the host; removing them there needs sudo.
- **Logs:** `journalctl -u nesbox@steam-microvm-nvidia -u
  nvgpu@steam-microvm-nvidia` on the host; in the guest, `journalctl -u
  moonshine@steam` for the server and `journalctl --user -u
  moonshine-session` for the app, and `~/.local/share/Steam/logs/`.

## Known issues

- **Steam's overlay is not drawn over games** (Moonshine 0.16.1): when
  Steam opens it, input goes to the overlay but the game stays on screen, and
  the game looks frozen. Closing the overlay (Home again) gives the game its
  input back.
- **Shared-window extents leak** in the backend: unmaps keyed by CPU address
  are not matched. A long session can exhaust the window; restart the VM.
- **SELinux is off** in the guest (`selinux=0`): the flattened rootfs has no
  labels.
- **SSH keys are written into the rootfs** by `build-rootfs.sh`.
- **Moonlight passes alt-tab** to the guest unless its "capture system
  keyboard shortcuts" setting is off.
- **32-bit `RM_CONTROL 0x215`** is refused by the backend (its struct size
  differs on i386); nothing observed fails from it.

How the image is put together, and why each piece is there:
[docs/design.md](docs/design.md). What this VM needs from virtio-nvgpu
upstream: [docs/virtio-nvgpu-upstream.md](docs/virtio-nvgpu-upstream.md).

## Troubleshooting

| symptom | look at |
| --- | --- |
| game shows "no suitable graphics card" or crashes at start | `journalctl -u nvgpu@steam-microvm-nvidia` for `Too many open files` or `SHM alloc failed` (see [Requirements](#requirements)) |
| VM stops with `KVM_RUN failed: Bad address` | something used the nvidia-drm modeset path (an Xorg started?) |
| Moonlight can't start an app, or shows a black screen | `journalctl -u moonshine@steam` in the guest; `moonshine healthcheck` as steam checks the GPU, encoder and input access |
| app fails to start right after quitting one | the previous app is still stopping; start it again |
| game looks frozen, input goes nowhere | Steam's overlay is open but not drawn (see [Known issues](#known-issues)); press Home |
| no Decky in the Quick Access menu | `systemctl status plugin_loader`; `ss -ltn` should show 127.0.0.1:8080 once Steam is up |
| Xbox controller not seen | on Proxmox `cat /sys/bus/usb/devices/3-3:1.0/active_clients`, `journalctl -u xone-relay-sender`; in the guest `journalctl -u xone-relay-receiver`, `grep -iA8 xbox /proc/bus/input/devices`, `sudo evtest`. If `active_clients` is 0, the controller/Xbox Wireless Adapter RF link is down, not the relay |
| Proton-CachyOS not in a game's Compatibility list | `toolmanifest.vdf` under `/usr/share/steam/compatibilitytools.d/proton-cachyos`; restart Steam |
| session killed mid-game | guest `journalctl -k` for the OOM killer; raise `MEM_MIB` |
| `install.sh` network step fails with EBUSY | something (a macvlan) holds the NIC |
