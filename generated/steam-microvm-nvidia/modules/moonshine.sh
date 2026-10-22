#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/moonshine
export MODDIR

export ASSET_MOONSHINE_VERSION="0.16.1"
export ASSET_MOONSHINE_URL="https://github.com/hgaiser/moonshine/releases/download/v0.16.1/moonshine-0.16.1-1.x86_64.rpm"
export ASSET_MOONSHINE_SHA256="9540ae5b88828bb3b8c442eb4794644aceb66fa4b623afc65ea0f29146fae267"

source /ctx/modules/moonshine/module.sh

cp -rT /ctx/modules/moonshine/files /
