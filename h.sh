#!/bin/sh
# Reconfigure Guix Home. substitutes.nonguix.org stalls without VPN, so
# bring the AmneziaWG tunnel up first (no-op if already up).
#
#   sh ~/dotfiles/h.sh

set -e
cd "$(dirname "$0")"
sudo herd start amneziawg
guix home reconfigure home.scm
