#!/bin/sh

# Author: ConzZah
# Project: alpine-xfce4raspi
# File: resize_sd.sh
# /// this firstboot script is responsible for expanding sdcards to their original capacity ///

# NOTE: THIS SCRIPT IS ONLY INVOKED WHEN FIRSTBOOT IS ACTIVE!
# it needs to be placed in /etc/.firstboot
# and /etc/.firstboot/firstboot has to exist.

### get the first sector of the 2nd partiton so we don't hardcode any values
p2_start="$(sudo fdisk -l| grep mmcblk0p2 | tr -s ' '| cut -d ' ' -f 4)"

repart () {
### repartition/expand sdcard with fdisk on firstboot
(
echo d # delete partition 
echo 2 # partition number 
echo n # create partition 
echo p # Primary partition   
echo 2 # Partition number (2nd)
echo "$p2_start" # First sector of 2nd partition ( everything below this is the first partition, which we don't want to overwrite. )
echo "" # Last sector of 2nd (on no input, fdisk defaults to whatever the last sector is automagically)
echo w # Write changes to disk
) | sudo fdisk /dev/mmcblk0

### create .repart file as indicator to run resize2fs
sudo touch /etc/.firstboot/.repart && sudo reboot 
}

### reboot & expand filesystem 
## if .repart exists, we know that fdisk already ran, so onto resize2fs
[ -f /etc/.firstboot/.repart  ] && { sudo resize2fs -f /dev/mmcblk0p2; sudo rm -rf /etc/.firstboot/; sudo reboot ;}


### if .repart doesn't already exist, run repart.
[ ! -f /etc/.firstboot/.repart ] && { repart ;}
