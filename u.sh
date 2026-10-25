#!/bin/sh
# Reconfigure the installed X1 with nonguix substitutes relayed by the
# CachyOS laptop (see p.sh); substitutes.nonguix.org stalls without VPN.
#
#   sh ~/dotfiles/u.sh

set -e
cd "$(dirname "$0")"
sudo guix system reconfigure system.scm \
     --substitute-urls="https://bordeaux.guix.gnu.org http://192.168.1.182:8080"
