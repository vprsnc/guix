#!/bin/sh
# First reconfigure on the installed X1: put the real disk UUIDs into
# system.scm (it ships with placeholders), then reconfigure with nonguix
# substitutes relayed by the CachyOS laptop (see p.sh).
#
#   sh ~/dotfiles/u.sh

set -e
cd "$(dirname "$0")"
relay=http://192.168.1.182:8080

luks=$(sudo blkid -s UUID -o value /dev/nvme0n1p2)
efi=$(sudo blkid -s UUID -o value /dev/nvme0n1p1)
echo "LUKS $luks   EFI $efi"
[ -n "$luks" ] && [ -n "$efi" ] || { echo "UUIDs not found" >&2; exit 1; }

sed -i -e "s/00000000-0000-0000-0000-000000000000/$luks/" \
       -e "s/\"0000-0000\"/\"$efi\"/" system.scm
grep -n -E "uuid" system.scm

curl -sf -m 10 "$relay/nix-cache-info" >/dev/null || {
    echo "Relay $relay not reachable; start it on CachyOS first." >&2
    exit 1
}

sudo guix system reconfigure system.scm \
     --substitute-urls="https://bordeaux.guix.gnu.org $relay"
