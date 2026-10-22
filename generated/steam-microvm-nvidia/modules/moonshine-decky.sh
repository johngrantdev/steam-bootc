#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/moonshine-decky
export MODDIR

export ASSET_MOONSHINE_DECKY_VERSION="0.1.0"
export ASSET_MOONSHINE_DECKY_URL="https://github.com/johngrantdev/moonshine-decky/releases/download/v0.1.0/moonshine-decky-v0.1.0.zip"
export ASSET_MOONSHINE_DECKY_SHA256="7078b18685cc7df0aa1be5ec10afb136a85036b37fd8cfdac0bae07d26a0cef0"

source /ctx/lib/family.sh

install_packages 'unzip'

source /ctx/modules/moonshine-decky/module.sh
