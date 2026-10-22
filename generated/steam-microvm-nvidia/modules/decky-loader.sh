#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/decky-loader
export MODDIR

export ASSET_DECKY_VERSION="3.2.10"
export ASSET_DECKY_URL="https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v3.2.10/PluginLoader"
export ASSET_DECKY_SHA256="c2cf316a53e1c1d318c6dda8821c827e5db275922987f9097956d7a1576e8258"

source /ctx/lib/family.sh

install_packages 'flatpak'

source /ctx/modules/decky-loader/module.sh

cp -rT /ctx/modules/decky-loader/files /
chmod '0755' -- '/usr/libexec/steam-session/decky-start'
