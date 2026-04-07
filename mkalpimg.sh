#!/usr/bin/env sh

# Author: ConzZah
# Project: alpine-xfce4raspi
# File: mkalpimg.sh
# /// trim sdcards and extract images ///

# this script is for trimming sdcards, making an image with dd and finally compressing it with xz
# it uses resize2fs to resize the filesystem of the 2nd partition to the specified size, and then fdisk to recreate the partitions

### init
init () {
part1="1"
part2="2"
sudo fdisk -l
printf '\n\n%s' "DEVICE ( example: /dev/sdb ): "; read -r device; echo ""
printf '%s' "SHRINK TO: ( example: +<int>M/G   ): "; read -r size; echo ""
printf '%s' "IMAGE VERSION: "; read -r image_version_number; echo ""

## if $device is /dev/mmcblkX, fix $part vars
printf '%s' "$device"| grep -q '/dev/mmcblk.*' && { part1="p1"; part2="p2" ;}

## check if $device is currently mounted and exit if it is
mount| grep -q "$device" && printf '\n%s\n\n' "ERROR: $device IS STILL MOUNTED! EXITING.." && exit 1

## get the current alpine version number
alpine_version="$(curl -sL "https://alpinelinux.org/downloads/"| grep "Current Alpine Version"| cut -d '<' -f 3| cut -d '>' -f 2)"

## spit out a name for our .img
img="alpine-xfce4raspi-aarch64-${alpine_version}_$(date "+%Y-%m-%d")_${image_version_number}.img"
are_u_sure_about_that
}

### sanitycheck
are_u_sure_about_that () {
## ask the user if they really want to proceed
printf '\n%s\n\n' "PROCEED WITH THESE VALUES? ( PLEASE BE SURE BEFORE YOU CONTINUE )"
printf '%s\n\n' "DEVICE: $device"
printf '%s\n\n' "SHRINK TO SIZE: $size"
printf '%s' "[y/n/r] "
read -r ynr; case $ynr in
y|Y) ! fixfs && exit 1; resizefs_p2 ;; n|N) exit ;; r|R) init ;;
*) exit
esac
}

### resize2fs
resizefs_p2 () {
printf "\nRESIZING SDCARD ..\n"
! sudo resize2fs "${device}${part2}" "${size}" && echo "RESIZE FAILED" || echo "RESIZE COMPLETE."
recreate_parttable
}

### recreate_parttable
recreate_parttable () {
get_start_and_end_sectors
(echo "d" # delete partition
echo "2" # partition number
echo "n" # create partition
echo "p" # Primary partition
echo "2" # Partition number (2nd)
echo "$p2_start" # First sector of 2nd part ( everything below is the first partition, which we don't want to overwrite. )
echo "$size" # +M/G value of 2nd partition
echo "w" # Write changes to disk
) | sudo fdisk "${device}"
printf "\nSDCARD PARTITIONED.\n"
create_img
}

### create_img
create_img () {
get_start_and_end_sectors
printf  "\nCREATING IMAGE WITH DD ..\n"
sudo dd if="${device}" of="$img" count="$p2_end"
printf '%s\n' "COMPRESSING IMAGE WITH XZ .."
! sudo xz -kev8 "$img" && exit 1
exit 0
}

get_start_and_end_sectors () {
p2_start="$(sudo fdisk -l| grep "${device}${part2}" | tr -s ' '| cut -d ' ' -f 2)"
p2_end="$(sudo fdisk -l| grep "${device}${part2}" | tr -s ' '| cut -d ' '  -f 3)"
}

### fixfs
fixfs () {
printf "CHECKING FILESYSTEMS..\n"
sudo fsck.fat "${device}${part1}"
sudo e2fsck -fy "${device}${part2}"
sync
}

init
