#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/session
export MODDIR

source /ctx/lib/family.sh

install_packages 'pciutils' 'glibc-langpack-en' 'zram-generator-defaults' 'mangohud' 'liberation-fonts' 'google-noto-sans-cjk-vf-fonts'

cp -rT /ctx/modules/session/files /
chmod '0755' -- '/usr/libexec/steam-session/steam-gamemode'
chmod '0755' -- '/usr/bin/steamos-update'
chmod '0755' -- '/usr/bin/steamos-session-select'
chmod '0755' -- '/usr/bin/steamos-select-branch'
chmod '0755' -- '/usr/bin/jupiter-biosupdate'
chmod '0755' -- '/usr/bin/jupiter-initial-firmware-update'
chmod '0755' -- '/usr/bin/steamos-mandatory-update'
chmod '0755' -- '/usr/bin/steamos-polkit-helpers/steamos-update'
chmod '0755' -- '/usr/bin/steamos-polkit-helpers/steamos-select-branch'
chmod '0755' -- '/usr/bin/steamos-polkit-helpers/jupiter-biosupdate'
chmod '0755' -- '/usr/bin/steamos-polkit-helpers/jupiter-dock-updater'
