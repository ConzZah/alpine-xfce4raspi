#!/usr/bin/env sh

# Author: ConzZah
# Project: alpine-xfce4raspi
# File: bootstrap.sh
# /// bootstrap / pre-setup script ///

## set vars
root_pass="${root_pass:-123}"
hostname="${hostname:-alpine}"
tz="${tz:-Europe/Berlin}"
kbd_lay="${kbd_lay:-de}"
kbd_var="${kbd_var:-de}"
modulesdir='/lib/modules'

## set hostname
setup-hostname "$hostname"
hostname "$hostname"

## restart hostname service
rc-service hostname restart

## setup keymap
setup-keymap "${kbd_lay}" "${kbd_var}"

## setup timezone
setup-timezone -i "${tz}"

## setup interfaces and (re)start networking
setup-interfaces -a -r

## start networking on boot
rc-update add networking boot

## start crond on boot
rc-update add crond boot

## setup ntp
setup-ntp chrony

## setup ssh
setup-sshd openssh

## setup repos
setup-apkrepos -c -1

## change password for root
printf '%s' "root:${root_pass}"| chpasswd

## copy apks to /root
cp -fr /media/mmcblk0p1/apks /root

## edit /etc/apk/repositories to point to /root (just for the install)
sed -i 's#/media/mmcblk0p1#/root#g' /etc/apk/repositories

## backup $modulesdir,
## so we can restore it after unmounting mmcblk0p1
## if $modulesdir is a link, traverse to obtain it's actual path
[ -L "$modulesdir" ] && modulesdir=$(readlink "$modulesdir")

## backup modules
cp -a "$modulesdir" /lib/modules.tmp

## stop modloop service
rc-service modloop stop

## remove modules
rm -r /lib/modules

## restore modules
mv /lib/modules.tmp /lib/modules

## unmount mmcblk0p1
umount /media/mmcblk0p1

## setup disk
printf 'y'| setup-disk -m sys /dev/mmcblk0

## point to /media/mmcblk0p1 again in repositories
sed -i 's#/root#/media/mmcblk0p1#g' /etc/apk/repositories

## create tmpmnt
mkdir -p /root/tmpmnt

## mount /dev/mmcblk0p2 and cd to root to prep the main setup script
mount "/dev/mmcblk0p2" "/root/tmpmnt"
cd '/root/tmpmnt/root' || exit 1

## download setup.sh
wget "https://github.com/ConzZah/alpine-xfce4raspi/raw/refs/heads/main/setup.sh"
chmod +x 'setup.sh'

## append to crontab (which will get overwritten by setup.sh at runtime)
echo  '@reboot [ -f /root/setup.sh ] && { /bin/sh /root/setup.sh; rm -f /root/setup.sh ;}
' >> '/root/tmpmnt/var/spool/cron/crontabs/root'

## cd, unmount & reboot
cd || exit 1
umount /root/tmpmnt
sync
reboot
