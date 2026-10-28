#!/bin/sh
# Reconfigure the installed X1. substitutes.nonguix.org stalls without
# VPN, so bring the AmneziaWG tunnel up first (no-op if already up).
#
#   sh ~/dotfiles/u.sh

set -e
cd "$(dirname "$0")"
sudo herd start amneziawg
sudo guix system reconfigure system.scm
