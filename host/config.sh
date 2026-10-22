# shellcheck shell=bash
# Settings shared by the host scripts: host/steam-bootc.conf (or
# $STEAM_BOOTC_CONF) if present, then the environment, then these defaults.
# See steam-bootc.conf.example.
conf=${STEAM_BOOTC_CONF:-$(dirname "${BASH_SOURCE[0]}")/steam-bootc.conf}
# shellcheck source=/dev/null
[ ! -f "$conf" ] || . "$conf"

NAME=${NAME:-steam-microvm-nvidia}
GAMES=${GAMES:-$HOME/Games}
OUT=${OUT:-$HOME/.local/share/$NAME}
IMAGE=${IMAGE:-localhost/steam-microvm-nvidia:latest}
SIZE=${SIZE:-20G}
KEYS=${KEYS:-}
VCPUS=${VCPUS:-8}
MEM_MIB=${MEM_MIB:-12288}
NIC=${NIC:-}
BRIDGE=${BRIDGE:-br0}
TAP=${TAP:-steamvm0}
MAC=${MAC:-02:57:56:00:00:01}
HOST_LINK=${HOST_LINK:-}
