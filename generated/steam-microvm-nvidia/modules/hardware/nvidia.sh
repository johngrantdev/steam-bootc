#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/hardware/nvidia
export MODDIR

export OPT_VERSION="615.71.09"
export OPT_KERNEL_MODULES="0"
export ASSET_REPO_KEY_VERSION="73CD9B30"
export ASSET_REPO_KEY_URL="https://developer.download.nvidia.com/compute/cuda/repos/fedora44/x86_64/73CD9B30.pub"
export ASSET_REPO_KEY_SHA256="9221458f62030a18d5a28eecf44496016ff9c11548492ac2ce428f75c7513cab"

source /ctx/modules/hardware/nvidia/module.sh

cp -rT /ctx/modules/hardware/nvidia/files /
