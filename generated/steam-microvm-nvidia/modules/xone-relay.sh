#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/xone-relay
export MODDIR

export ASSET_RELAY_VERSION="0.1.0"
export ASSET_RELAY_URL="https://github.com/johngrantdev/xone-relay/releases/download/v0.1.0/xone-relay"
export ASSET_RELAY_SHA256="254fe85c4700fbac115beecb9bd66da2d0c20f1c9900af54d86fd223d738b6ea"

source /ctx/lib/family.sh

install_packages 'kmod'

source /ctx/modules/xone-relay/module.sh

cp -rT /ctx/modules/xone-relay/files /
chmod '0755' -- '/usr/libexec/steam-session/xone-relay-receiver'
