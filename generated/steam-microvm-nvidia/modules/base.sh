#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/base
export MODDIR

source /ctx/lib/family.sh

install_packages 'openssh-server' 'NetworkManager' 'curl' 'tar' 'xz' 'less' 'nano' 'strace' 'iproute' 'bind-utils'

cp -rT /ctx/modules/base/files /
