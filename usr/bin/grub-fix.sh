#!/usr/bin/env bash
#shellcheck disable=SC2155,SC2034
#shellcheck source=/dev/null

#  /usr/bin/grub-fix.sh
#  Description: Big Store installing programs for BigLinux
#
#  Created: 2020/01/11
#  Altered: 2024/08/19
#
#  Copyright (c) 2023-2024, Vilmar Catafesta <vcatafesta@gmail.com>
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

APP="${0##*/}"
_VERSION_="1.0.0-20240819"
#
LIBRARY=${LIBRARY:-'/usr/share/bigbashview/bcc/shell'}
[[ -f "${LIBRARY}/bcclib.sh" ]] && source "${LIBRARY}/bcclib.sh"
[[ -f "${LIBRARY}/tinilib.sh" ]] && source "${LIBRARY}/tinilib.sh"

function sh_grub-fix_sh_main() {
	#sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"|GRUB_CMDLINE_LINUX_DEFAULT=\"$(cat /proc/cmdline | sed 's|.*misolabel=[[:alnum:]_-]*||g;s|bootsplash.bootfile=[[:alnum:]/_-]*||g;s|quiet systemd.show_status=1||g;s|driver=nonfree||g;s|driver=free||g;s|nouveau.modeset=0 i915.modeset=1 radeon.modeset=1||g;s|nouveau.modeset=1 i915.modeset=1 radeon.modeset=1||g')|g" $*
	sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT='|GRUB_CMDLINE_LINUX_DEFAULT='$(sed 's|BOOT_IMAGE=/boot/vmlinuz-x86_64 ||g;s| driver=nonfree||g;s| driver=free||g;s| rdinit=/vtoy/vtoy||g;s| quiet splash||g' /proc/cmdline) |g" $*
	sed -i 's|BOOT_IMAGE=/boot/vmlinuz-x86_64||g;s|misobasedir=manjaro misolabel=BIGLINUXLIVE ||g' $*
	sed -i 's|GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/biglinux/theme.txt"|g' $*
	sed -i 's|GRUB_SAVEDEFAULT=true|GRUB_SAVEDEFAULT=false|g;s|quiet quiet|quiet|g' $*

	if ! grep -q GRUB_EARLY_INITRD_LINUX_STOCK $*; then
		echo "GRUB_EARLY_INITRD_LINUX_STOCK=''" >>$*
	fi

	\nGRUB_EARLY_INITRD_LINUX_STOCK=""

	#remove multiples splash
	while [ "$(grep -o '[^[:space:]]*splash[^[:space:]]*' $* | sed 's/\"//' | wc -w)" -gt "1" ]; do
		sed -i 's/ splash//' $*
	done

	#remove multiples quiet
	while [ "$(grep -o '[^[:space:]]*quiet[^[:space:]]*' $* | sed 's/\"//' | wc -w)" -gt "1" ]; do
		sed -i 's/ quiet//' $*
	done

	#Change default desktop in sddm to use in livecd
	if grep -q wayland /proc/cmdline; then
		echo "[Last]
    Session=/usr/share/wayland-sessions/plasmawayland.desktop" >$(echo "$*" | sed 's|etc/default/grub|var/lib/sddm/state.conf|g')
	else
		echo "[Last]
    Session=/usr/share/xsessions/plasma.desktop" >$(echo "$*" | sed 's|etc/default/grub|var/lib/sddm/state.conf|g')
	fi
	# sed -i "s|Session=plasma.desktop|Session=plasma-biglinux-x11.desktop|g" $(echo "$*" | sed 's|etc/default/grub|etc/sddm.conf|g')

	# use compress-force=zstd:5 in / and not number in all other
	sed -i -e '/\s\/\s/ s/zstd:9/zstd:5/' -e '/\s\/\s/! s/zstd:9/zstd/' $(echo "$*" | sed 's|etc/default/grub|/etc/fstab|g')

	# Save default KDE configuration
	cp -f "/etc/big_desktop_changed" $(echo "$*" | sed 's|etc/default/grub|/etc/big_desktop_changed|g')

	# if [ -e "/tmp/use_disable_fsync" ]; then
	#     echo '/usr/$LIB/disable-fsync.so' > $(echo "$*" | sed 's|etc/default/grub|etc/ld.so.preload|g')
	# fi
	cp -f /tmp/big_desktop_theme $(echo "$*" | sed 's|etc/default/grub|etc/default-theme-biglinux|g')
}
export -f sh_grub-fix_sh_main

sh_grub-fix_sh_main "$@"
