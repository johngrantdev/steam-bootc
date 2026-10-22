#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/vm/nvidia-guest
export MODDIR

source /ctx/modules/vm/nvidia-guest/module.sh

cp -rT /ctx/modules/vm/nvidia-guest/files /
chmod '0755' -- '/usr/bin/nvidia-modprobe'
