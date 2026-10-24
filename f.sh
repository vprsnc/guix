#!/bin/sh
# GDM 49 crashes on this install ("pick_username: code should not be
# reached") and leaves the console dead.  From the install ISO: swap GDM
# for LightDM in the installed config and reinstall.  nonguix substitutes
# come through the CachyOS relay (see p.sh), so start it first.
#
#   curl -LO https://raw.githubusercontent.com/vprsnc/guix/main/f.sh
#   sh f.sh

set -e
c=/mnt/etc/config.scm
relay=http://192.168.1.182:8080

[ -e /dev/mapper/cryptroot ] || cryptsetup open /dev/nvme0n1p2 cryptroot
mountpoint -q /mnt || mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot/efi
mountpoint -q /mnt/boot/efi || mount /dev/nvme0n1p1 /mnt/boot/efi

if ! grep -q lightdm "$c"; then
    cp "$c" "$c.gdm"
    # LightDM takes the Xorg settings (keyboard layout) that the
    # installer passes to set-xorg-configuration, which targets GDM.
    sed -i '0,/^(use-service-modules/s//(use-service-modules lightdm)\n(define (set-xorg-configuration xorg)\n  (service lightdm-service-type\n           (lightdm-configuration (xorg-configuration xorg))))\n(use-service-modules/' "$c"
    sed -i 's/^\([[:space:]]*\)%desktop-services/\1(modify-services %desktop-services (delete gdm-service-type))/' "$c"
fi
grep -q 'delete gdm-service-type' "$c" || {
    echo "Could not remove GDM from $c; edit it by hand." >&2
    exit 1
}

curl -sf -m 10 "$relay/nix-cache-info" >/dev/null || {
    echo "Relay $relay not reachable; start it on CachyOS first." >&2
    exit 1
}

herd start cow-store /mnt
guix system init \
     --substitute-urls="https://bordeaux.guix.gnu.org $relay" \
     "$c" /mnt
echo "Done. Type: reboot   (and pull the USB stick)"
