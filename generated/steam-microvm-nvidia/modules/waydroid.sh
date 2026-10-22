#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/waydroid
export MODDIR

source /ctx/lib/family.sh

install_packages 'waydroid' 'cage' 'wlr-randr' 'zenity'

cp -rT /ctx/modules/waydroid/files /
chmod '0755' -- '/usr/bin/waydroid-launcher'
chmod '0755' -- '/usr/libexec/steam-session/waydroid-container-start'
chmod '0755' -- '/usr/libexec/steam-session/waydroid-fix-controllers'
