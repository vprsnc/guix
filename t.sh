#!/bin/sh
# Install hang: small substitutes download, big ones stall.  Fetch one
# big nar from each server with a progress meter; curl gives up (exit
# 28) if the speed stays under 10 KB/s for 20 s.  Then retry with a
# smaller MTU and Wi-Fi power saving off, the usual culprits.
#
#   curl -LO https://raw.githubusercontent.com/vprsnc/guix/main/t.sh
#   sh t.sh

test_big () {
    for u in \
        https://bordeaux.guix.gnu.org/nar/lzip/2hacvnv2hcqkxv6c8vzkbi5wd6r48l35-emacs-31.1 \
        https://substitutes.nonguix.org/nar/zstd/66s2ysczqqnyyrd31ksd10wks067bm71-linux-7.2.8
    do
        echo "== ${u%%/nar*}"
        curl -o /dev/null -m 180 -Y 10000 -y 20 "$u"
        echo "exit $? (0 = ok, 28 = stalled)"
    done
}

test_big

w=$(ls /sys/class/net | grep -m1 '^wl')
echo "== retry with $w: MTU 1400, power saving off"
ip link set "$w" mtu 1400
iw dev "$w" set power_save off 2>/dev/null || true
test_big
