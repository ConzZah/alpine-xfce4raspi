#!/usr/bin/env sh

# Author: ConzZah
# Project: alpine-xfce4raspi
# File: setup.sh
# /// core setup script ///

## set vars
user="${user:-user}"
user_pass="${user_pass:-123}"
gpu_memory="${gpu_memory:-512}"
img="alpine-xfce4raspi"

cd '/tmp' || exit 1

## install basics
apk add git sed sudo curl bash 7zip

## install minimal dev packages
apk add build-base cmake linux-headers "linux-$(uname -r| rev| cut -d '-' -f 1| rev)-dev"

## install chocolate-doom and featherpad from testing
apk add chocolate-doom featherpad --repository="http://dl-cdn.alpinelinux.org/alpine/edge/testing"

### install SameBoy
## download, extract & install prebuilt SameBoy
curl -LO "https://github.com/ConzZah/sameboy4alpine/releases/download/latest/SameBoy-$(uname -m).7z"
7z x -y "SameBoy-$(uname -m).7z"
sh SameBoy/install.sh
rm -fr "SameBoy-$(uname -m).7z" "Sameboy"

## create $user
setup-user -a -g audio,input,video,netdev "${user}"

## change password for $user
printf '%s' "${user}:${user_pass}"| chpasswd

## add $user to sudoers
echo "${user} ALL=(ALL:ALL) ALL" > "${user}"
mv "${user}" "/etc/sudoers.d/${user}"
chmod 0440 "/etc/sudoers.d/${user}"

## install dotfiles
curl -LO "https://github.com/ConzZah/alpine-xfce4-bs/raw/refs/heads/main/dotfilez.7z"
7z x -y "dotfilez.7z" -o"/home/$user"
rm -f "dotfilez.7z"

## install resize_sd.sh
curl -LO "https://github.com/ConzZah/alpine-xfce4raspi/raw/refs/heads/main/resize_sd.sh"
mkdir -p '/etc/.firstboot'
chmod +x 'resize_sd.sh'
mv -f 'resize_sd.sh' '/etc/.firstboot'

## install /boot/usercfg.txt
echo "dtoverlay=vc4-kms-v3d
disable_overscan=1
dtparam=audio=on
gpu_mem=${gpu_memory}
arm_boost=1" > 'usercfg.txt'
mv -f 'usercfg.txt' '/boot/usercfg.txt'

## install xorg patch for raspi 5
echo 'Section "OutputClass"
Identifier "vc4"
MatchDriver "vc4"
Driver "modesetting"
Option "PrimaryGPU" "true"
EndSection
' > '99-vc4.conf'
mkdir -p '/etc/X11/xorg.conf.d/'
mv -f 99-vc4.conf '/etc/X11/xorg.conf.d/'

## edit /etc/mke2fs.conf to enable periodic fscks
sed -i 's#enable_periodic_fsck = 0#enable_periodic_fsck = 1#g' '/etc/mke2fs.conf'

## clone core setup scripts
git clone --depth=1 'https://github.com/conzzah/essentials4alpine'
git clone --depth=1 'https://github.com/conzzah/xfce4alpine'
git clone --depth=1 'https://github.com/conzzah/nm4alpine'

## format setup scripts
sed -i -e 's/; read -n1 -s//g' -e 's/doas //g' -e "s#\$USER#$user#g" \
'essentials4alpine/essentials4alpine.sh' \
'xfce4alpine/xfce4alpine.sh' \
'nm4alpine/nm4alpine.sh'

## install setup scripts
sh 'essentials4alpine/essentials4alpine.sh'
sh 'xfce4alpine/xfce4alpine.sh'
sh 'nm4alpine/nm4alpine.sh'

## install root crontab
echo '# do daily/weekly/monthly maintenance
# min	hour	day	month	weekday	command
*/15	*	*	*	*	run-parts /etc/periodic/15min
0	*	*	*	*	run-parts /etc/periodic/hourly
0	2	*	*	*	run-parts /etc/periodic/daily
0	3	*	*	6	run-parts /etc/periodic/weekly
0	5	1	*	*	run-parts /etc/periodic/monthly

### FIRSTBOOT STUFF ###

# if .firstboot exist, generate ssh keys @ reboot, then remove /etc/firstboot so we only regen once.
@reboot [ -f /etc/.firstboot/firstboot ] && { rm /etc/.firstboot/firstboot; rm /etc/ssh/ssh_host_*; ssh-keygen -A; sh /etc/.firstboot/resize_sd.sh ;}
@reboot [ -f /etc/.firstboot/.repart ] && sh /etc/.firstboot/resize_sd.sh

### FIXES ###

# restart chronyd as soon as we have internet, so we get the system time right:
@reboot { until ping -q -c 1 -w 1 google.com; do sleep 1; done; rc-service chronyd restart ;} &
' > 'crontab'; mv -f 'crontab' '/var/spool/cron/crontabs/root'

## install /etc/motd
echo "

Welcome to Alpine!

you are running: $img by ConzZah

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <https://wiki.alpinelinux.org/>.

You may change this message by editing /etc/motd.

" > 'motd'; rm -f '/etc/motd'; mv -f 'motd' '/etc/'

## update xdg-user-dirs manually
# shellcheck disable=SC2016
######## RATIONALE ########
# we don't want the expressions to expand,
# since we need them literally here
echo '
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
' > 'user-dirs.dirs'; mv -f 'user-dirs.dirs' "/home/$user/.config/user-dirs.dirs"

## create xdg-user-dirs manually
mkdir -p \
"/home/$user/Desktop" \
"/home/$user/Downloads" \
"/home/$user/Templates" \
"/home/$user/Public" \
"/home/$user/Documents" \
"/home/$user/Music" \
"/home/$user/Pictures" \
"/home/$user/Videos"

## write bt.sh and move it to /home/$user
## this script currently requires manual execution
echo "#!/bin/sh
git clone --depth=1 https://github.com/conzzah/bt4alpine
sh bt4alpine/bt4alpine.sh
rm -rf bt4alpine
rm /home/$user/bt.sh
doas reboot" > bt.sh
chmod +x bt.sh
mv bt.sh "/home/$user/bt.sh"

## change default shell to bash
chsh "${user}" -s /bin/bash
chsh root -s /bin/bash

## change ownership of /home/$user
chown -R "${user}":"${user}" -- "/home/$user".*
chown -R "${user}":"${user}" -- "/home/$user"*

## reboot
sync; reboot
