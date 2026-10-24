#!/bin/sh
# Installed system boots but the console is dead (GDM/X grabs the VT).
# From the install ISO: open and mount the installed root, then print the
# GPU driver and the GDM/X errors on one screen.
#
#   curl -LO https://raw.githubusercontent.com/vprsnc/guix/main/d.sh
#   sh d.sh

[ -e /dev/mapper/cryptroot ] || cryptsetup open /dev/nvme0n1p2 cryptroot
mountpoint -q /mnt || mount /dev/mapper/cryptroot /mnt

echo "== GPU"
grep -h -E '^(DRIVER|PCI_ID)=' /sys/class/drm/card*/device/uevent 2>/dev/null | sort -u | tr '\n' ' '
echo
grep -m1 'model name' /proc/cpuinfo

echo "== services in config"
grep -o -E '%desktop-services|gnome|xfce|mate|lxqt|sway|enlightenment|gdm|slim|sddm' /mnt/etc/config.scm | sort -u | tr '\n' ' '
echo

echo "== messages"
grep -i -E 'gdm|xorg|wayland|i915|xe |drm|failed|respawn' /mnt/var/log/messages \
    | grep -v -i -E 'acpi|firmware: direct' | tail -n 18 | cut -c1-160

echo "== X errors"
find /mnt/var/log /mnt/var/lib/gdm -name 'Xorg*.log' 2>/dev/null | head -2 | while read -r f; do
    echo "-- $f"; grep -E '\(EE\)' "$f" | tail -n 6 | cut -c1-160
done
