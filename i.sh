#!/bin/sh
# Finish a graphical install that hung before `guix system init`, by hand.
# The installer has already partitioned, opened LUKS, mounted /mnt and
# written /mnt/etc/config.scm (and the user's password).  This switches
# the config to the nonguix kernel and runs the install.
#
# From a root shell on the install ISO (Ctrl+Alt+F3):
#   loadkeys dvorak
#   curl -LO https://raw.githubusercontent.com/vprsnc/guix/main/i.sh
#   sh i.sh

set -e
c=/mnt/etc/config.scm

# Kill the stuck installer's container process without letting it clean
# up (that would unmount /mnt), then get guix-daemon back into our
# mount namespace.
p=$(pgrep -o -f installer-real || true)
if [ -n "$p" ]; then
    pkill -9 -P "$p" -f installer-real || true
fi
herd restart guix-daemon

if ! grep -q nongnu "$c"; then
    sed -i 's/^(use-modules (gnu))$/(use-modules (gnu) (nongnu packages linux) (nongnu system linux-initrd))/' "$c"
    sed -i 's/^(operating-system$/(operating-system\n  (kernel linux)\n  (initrd microcode-initrd)\n  (firmware (list linux-firmware))/' "$c"
fi
grep -q 'nongnu packages linux' "$c" && grep -q '(kernel linux)' "$c" || {
    echo "Could not add the nonguix kernel to $c; edit it by hand." >&2
    exit 1
}

mountpoint -q /mnt/boot/efi || mount /dev/nvme0n1p1 /mnt/boot/efi

head -25 "$c"
findmnt -R /mnt
printf 'Config and mounts above. Press Enter to install, Ctrl+C to stop. '
read -r _

herd start cow-store /mnt
guix system init "$c" /mnt
echo "Done. Type: reboot   (and pull the USB stick)"
