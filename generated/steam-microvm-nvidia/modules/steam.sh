#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/steam
export MODDIR

if [ -f /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
    echo "repo rpmfusion-nonfree is already configured"
else
    source /ctx/modules/steam/repo
fi

source /ctx/lib/family.sh

install_packages 'steam' 'gamemode' 'steam-devices' 'vulkan-loader' 'vulkan-tools' 'xdg-user-dirs' 'dbus' 'dbus-broker' 'zenity' 'xterm'
