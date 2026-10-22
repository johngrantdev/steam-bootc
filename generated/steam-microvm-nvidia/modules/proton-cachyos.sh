#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/proton-cachyos
export MODDIR

export ASSET_PROTON_VERSION="11.0-20261015-slr"
export ASSET_PROTON_URL="https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-11.0-20261015-slr/proton-cachyos-11.0-20261015-slr-x86_64.tar.xz"
export ASSET_PROTON_SHA256="35e16eab636724e3ed7aa8e2dbc33eb8e102e0c63bbc28b5a39af544c75d5bd3"

source /ctx/lib/family.sh

install_packages 'curl' 'tar' 'xz'

source /ctx/modules/proton-cachyos/module.sh
