#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/emudeck
export MODDIR

source /ctx/lib/family.sh

install_packages 'fuse' 'fuse-libs' 'git-core' 'rsync' 'lsb_release' 'jq' 'zenity' 'unzip'

cp -rT /ctx/modules/emudeck/files /
chmod '0755' -- '/usr/libexec/steam-session/emudeck-desktop'
