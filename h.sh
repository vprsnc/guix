#!/bin/sh
# Reconfigure Guix Home with nonguix substitutes relayed by the CachyOS
# laptop (see u.sh).
#
#   sh ~/dotfiles/h.sh

set -e
cd "$(dirname "$0")"
guix home reconfigure home.scm \
     --substitute-urls="https://bordeaux.guix.gnu.org http://192.168.1.182:8080"
