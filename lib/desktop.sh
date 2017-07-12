#!/bin/bash
#
# Copyright (c) 2015 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of tool chain https://github.com/igorpecovnik/lib
#

install_desktop ()
{
	display_alert "Installing desktop" "XFCE" "info"

	# add loading desktop splash service
	cp $SRC/packages/blobs/desktop/desktop-splash/desktop-splash.service $SDCARD/etc/systemd/system/desktop-splash.service

	if [[ $RELEASE == xenial ]]; then
		# install optimized firefox configuration
		# cp $SRC/config/firefox.conf $SDCARD/etc/firefox/syspref.js
		# install optimized chromium configuration
		cp $SRC/config/chromium.conf $SDCARD/etc/chromium-browser/default
	fi
	# install dedicated startup icons
	cp $SRC/packages/blobs/desktop/icons/${RELEASE}.png $SDCARD/usr/share/pixmaps

	# install default desktop settings
	cp -R $SRC/packages/blobs/desktop/skel/. $SDCARD/etc/skel
	cp -R $SRC/packages/blobs/desktop/skel/. $SDCARD/root

	# install wallpapers
	mkdir -p $SDCARD/usr/share/backgrounds/xfce/
	cp $SRC/packages/blobs/desktop/wallpapers/armbian*.jpg $SDCARD/usr/share/backgrounds/xfce/

	# Install custom icons and theme
	cp $SRC/packages/blobs/desktop/vibrancy-colors_2.4-trusty-Noobslab.com_all.deb $SDCARD/tmp/
	chroot $SDCARD /bin/bash -c "dpkg -i /tmp/vibrancy-colors_2.4-trusty-Noobslab.com_all.deb >/dev/null 2>&1"
	rm -f $SDCARD/tmp/*.deb

	# Enable network manager
	if [[ -f $SDCARD/etc/NetworkManager/NetworkManager.conf ]]; then
		sed "s/managed=\(.*\)/managed=true/g" -i $SDCARD/etc/NetworkManager/NetworkManager.conf
		# Disable dns management withing NM
		sed "s/\[main\]/\[main\]\ndns=none/g" -i $SDCARD/etc/NetworkManager/NetworkManager.conf
		printf '[keyfile]\nunmanaged-devices=interface-name:p2p0\n' >> $SDCARD/etc/NetworkManager/NetworkManager.conf
	fi

	# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
	if [[ -f $SDCARD/etc/pulse/default.pa ]]; then
		sed "s/load-module module-udev-detect$/& tsched=0/g" -i  $SDCARD/etc/pulse/default.pa
	fi

	# Disable desktop mode autostart for now to enforce creation of normal user account
	sed "s/NODM_ENABLED=\(.*\)/NODM_ENABLED=false/g" -i $SDCARD/etc/default/nodm

	# Compile Turbo Frame buffer for sunxi
	if [[ $LINUXFAMILY == sun* && $BRANCH == default ]]; then
		sed 's/name="use_compositing" type="bool" value="true"/name="use_compositing" type="bool" value="false"/' -i $SDCARD/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
		sed 's/name="use_compositing" type="bool" value="true"/name="use_compositing" type="bool" value="false"/' -i $SDCARD/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

		# enable memory reservations
		echo "disp_mem_reserves=on" >> $SDCARD/boot/armbianEnv.txt
	fi
}
