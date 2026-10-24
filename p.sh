#!/bin/sh
# Resume the install with nonguix substitutes relayed by the CachyOS
# laptop (192.168.1.182:8080), which reaches substitutes.nonguix.org over
# its VPN.  Guix still checks nonguix's signatures.
#
#   curl -LO https://raw.githubusercontent.com/vprsnc/guix/main/p.sh
#   sh p.sh

set -e
relay=http://192.168.1.182:8080
curl -sf -m 10 "$relay/nix-cache-info" || {
    echo "Relay $relay not reachable; is it running on CachyOS?" >&2
    exit 1
}
herd restart guix-daemon
guix system init \
     --substitute-urls="https://bordeaux.guix.gnu.org $relay" \
     /mnt/etc/config.scm /mnt
echo "Done. Type: reboot   (and pull the USB stick)"
