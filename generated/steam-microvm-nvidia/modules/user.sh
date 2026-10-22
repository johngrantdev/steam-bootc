#!/usr/bin/env bash
# GENERATED FILE, do not edit.
set -euxo pipefail

MODDIR=/ctx/modules/user
export MODDIR

source /ctx/lib/family.sh

install_packages 'sudo'

cp -rT /ctx/modules/user/files /
