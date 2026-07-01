#!/bin/sh

# Author: ConzZah
# Project: alpine-xfce4raspi
# File: resize_sd.sh
# /// this firstboot script is responsible for expanding sdcards to their original capacity ///

# NOTE: THIS SCRIPT IS ONLY INVOKED WHEN FIRSTBOOT IS ACTIVE!
# it needs to be placed in /etc/.firstboot
# and /etc/.firstboot/firstboot has to exist.

## sleep some
sleep 10

### get the first sector of the 2nd partiton so we don't hardcode any values
p2_start="$(fdisk -l| grep mmcblk0p2 | tr -s ' '| cut -d ' ' -f 2)"

### repartition/expand sdcard with fdisk
(
echo d # delete partition 
echo 2 # partition number 
echo n # create partition 
echo p # Primary partition   
echo 2 # Partition number (2nd)
echo "$p2_start" # First sector of 2nd partition ( everything below this is the first partition, which we don't want to overwrite. )
echo "" # Last sector of 2nd (on no input, fdisk defaults to whatever the last sector is automagically)
echo w # Write changes to disk
) | fdisk /dev/mmcblk0

## run partprobe to tell the kernel that the tables have turned
partprobe

## run resize2fs
resize2fs -f /dev/mmcblk0p2

## remove the firstboot flag, but not this script, 
## so the user can upgrade to a larger sdcard by setting the flag again
rm -f /etc/.firstboot/firstboot
reboot
