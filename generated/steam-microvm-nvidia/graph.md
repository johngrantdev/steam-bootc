# steam-microvm-nvidia capability graph

GENERATED FILE, do not edit.

An arrow points from a provider to what needs it, dotted for `after`,
which orders the build without requiring anything. Layers build left to
right.

```mermaid
graph LR
    base["quay.io/fedora/fedora-bootc:44"]
    m0["fedora/build-environment"]
    m1["base"]
    m2["user"]
    m3["proton-cachyos"]
    m4["waydroid"]
    m5["boot/kernel-devel"]
    m6["hardware/nvidia"]
    m7["steam"]
    m8["moonshine"]
    m9["session"]
    m10["decky-loader"]
    m11["moonshine-decky"]
    m12["emudeck"]
    m13["vm/nvidia-guest"]
    m14["xone-relay"]
    m15["vm/nesbox-guest"]
    m16["vm/session"]
    base -->|"ssh"| m1
    m0 -->|"build-environment"| m1
    m0 -->|"build-environment"| m2
    m0 -->|"build-environment"| m3
    m0 -->|"build-environment"| m4
    m0 -->|"build-environment"| m6
    m0 -->|"build-environment"| m7
    m0 -->|"build-environment"| m8
    m0 -->|"build-environment"| m9
    m0 -->|"build-environment"| m10
    m0 -->|"build-environment"| m11
    m0 -->|"build-environment"| m13
    m0 -->|"build-environment"| m14
    m0 -->|"build-environment"| m15
    m2 -->|"user"| m4
    m2 -->|"user"| m7
    m2 -->|"user"| m8
    m2 -->|"user"| m9
    m2 -->|"user"| m10
    m2 -->|"user"| m12
    m5 -->|"kernel-devel"| m6
    m5 -->|"kernel-devel"| m13
    m6 -->|"nvidia-driver"| m7
    m6 -->|"nvidia-driver"| m8
    m6 -->|"nvidia-driver"| m13
    m7 -->|"steam"| m9
    m7 -->|"steam"| m10
    m7 -->|"steam"| m16
    m8 -->|"moonshine"| m9
    m8 -->|"moonshine"| m11
    m8 -->|"moonshine"| m12
    m9 -->|"game-session"| m16
    m10 -->|"decky-loader"| m11
```

## Capabilities

| Name | Kind | Provided by | Required by | After |
|---|---|---|---|---|
| `bootc` | capability | `base` |  |  |
| `bootupctl` | capability | `base` |  |  |
| `build-environment` | capability | `fedora/build-environment` | `base`, `user`, `proton-cachyos`, `waydroid`, `hardware/nvidia`, `steam`, `moonshine`, `session`, `decky-loader`, `moonshine-decky`, `vm/nvidia-guest`, `xone-relay`, `vm/nesbox-guest` |  |
| `crun` | capability | `base` |  |  |
| `decky-loader` | file | `decky-loader` | `moonshine-decky` |  |
| `game-session` | file | `session` | `vm/session` |  |
| `initramfs-generation` | capability | `base` |  |  |
| `kernel` | capability |  |  | `boot/kernel-devel` |
| `kernel-devel` | file, build only | `boot/kernel-devel` | `hardware/nvidia`, `vm/nvidia-guest` |  |
| `luks-initramfs` | capability | `base` |  |  |
| `moonshine` | file | `moonshine` | `session`, `moonshine-decky`, `emudeck` |  |
| `nvidia-driver` | file | `hardware/nvidia` | `steam`, `moonshine`, `vm/nvidia-guest` |  |
| `nvidia-kmod` | file | `hardware/nvidia` |  |  |
| `nvidia-repo` | file | `hardware/nvidia` |  |  |
| `podman` | capability | `base` |  |  |
| `rechunking` | capability | `base` |  |  |
| `secureboot-key` | capability |  |  | `hardware/nvidia` |
| `selinux-policy` | capability | `base` |  |  |
| `ssh` | capability | `base` | `base` |  |
| `steam` | file | `steam` | `session`, `decky-loader`, `vm/session` |  |
| `user` | file | `user` | `waydroid`, `steam`, `moonshine`, `session`, `decky-loader`, `emudeck` |  |
