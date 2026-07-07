#!/usr/bin/env sh

# Author: ConzZah
# Project: alpine-xfce4raspi
# File: mkalpimg.sh
# /// trim sdcards and extract images ///

# this script is for trimming sdcards, making an image with dd and finally compressing it with xz
# it uses resize2fs to resize the filesystem of the 2nd partition to the specified size, and then fdisk to recreate the partitions

image_name="alpine-xfce4raspi"

init () {
## depcheck
missing_deps=""
deps="resize2fs partprobe lsblk fdisk fsck.fat e2fsck mount sed cut dd xz tr df"
 
## update $PATH, so fdisk, fsck.fat, e2fsck, etc can be found
PATH="$PATH:/sbin:/usr/sbin"

for dep in $deps; do
! command -v "$dep" >/dev/null && \
missing_deps="$missing_deps $dep"
done

[ -n "$missing_deps" ] && \
printf '%s\n\n%s\n' "--> ERROR: THE FOLLOWING DEPENDENCIES ARE MISSING:" "$missing_deps" && exit 1

fdisk_l="$(sudo fdisk -l)"

printf '\n%s' "IMAGE VERSION: "; read -r image_version_number

printf '%s\n' "$fdisk_l"

printf '\n%s' "DEVICE ( example: /dev/sdb ): "; read -r device

## strip '/dev/' from $device
device_name="$(printf '%s\n' "$device"| sed 's#/dev/##g')"

## check if the $device actually exists, else exit here
! lsblk| grep -q "$device_name" && printf '%s\n' "--> ERROR: $device DOESN'T EXIST!" && exit 1

## create $tmpmnt
tmpmnt1="/tmp/tmpmnt1"
tmpmnt2="/tmp/tmpmnt2"
mkdir -p "$tmpmnt1"
mkdir -p "$tmpmnt2"

## set $part vars
part1="1"
part2="2"

## if $device is '/dev/mmcblkX', fix $part vars
printf '%s' "$device"| grep -q '/dev/mmcblk.*' && { part1="p1"; part2="p2" ;}

## if $device is currently mounted, unmount it
mount| grep "$device"| cut -d ' ' -f 3| \
while read -r mp
do
sudo umount "$mp" >/dev/null
done

## mount $device to /tmp/tmpmnt (1 & 2)
tmp_mount

## get the $image_arch
printf '%s\n' "--> TRYING TO GET THE IMAGE'S ARCHITECTURE"
[ ! -f "$tmpmnt2/etc/apk/arch" ] && \
printf '%s\n' "--> COULDN'T GET THE ARCHITECTURE OF THE IMAGE!" && exit 1
image_arch="$(cat "$tmpmnt2/etc/apk/arch")"
printf '%s\n' "--> THE IMAGE'S ARCHITECTURE SEEMS TO BE: $image_arch"

## get df to output in mebibytes
df_out="$(df -B M)"

### get values of the chosen $device
## here, we get the size of $device in bytes, and convert it to mebibytes
total_size_device="$(($(lsblk -b| grep -m1 "$device_name"| tr -s ' '| cut -d ' ' -f 4) / 1048576 ))"

## here, we get the total size of the first partition of $device
total_size_p1="$(printf '%s\n' "$df_out"| grep "tmpmnt1"| tr -s ' '| cut -d ' ' -f 2| sed 's#M##g')"

## here, we check how much of ${device}${part2} is actually used.
used_size_p2="$(printf '%s\n' "$df_out"| grep "$tmpmnt2"| tr -s ' '| cut -d ' ' -f 3| sed 's#M##g')"

## now we'll take $used_size_p2, and multiply it by 1.5 (we can do this by taking $used_size_p2, multiplying it by 3 and dividing it by 2)
new_size_p2="$((used_size_p2 * 3 / 2))"

### now let's calculate the $final_size that the resulting image is going to have.
## we'll add $total_size_p1 and $new_size_p2
final_size="$((total_size_p1 + new_size_p2))"

### make sure $final_size doesn't exceed $total_size_device, BEFORE we modify the partitions.
## BECAUSE: for resize2fs to succeed, we need to make sure that enough space is left on the $device for shrinking / expansion of the fs.. 
[ "$final_size" -gt "$total_size_device" ] && printf '%s\n' "--> ERROR: NO SPACE LEFT ON DEVICE!" && { tmp_unmount; exit 1 ;}

## make the final edit on the $size variable, so resize2fs & fdisk can use it.
size="+${final_size}M"

## get the current alpine version number
alpine_version="$(curl -sL "https://alpinelinux.org/downloads/"| grep -m1 "Current Alpine Version"| cut -d '<' -f 3| cut -d '>' -f 2)"

## spit out a name for our .img
img="${image_name}-${image_arch}-${alpine_version}-$(date "+%Y-%m-%d")-${image_version_number}.img"
are_u_sure_about_that
}


### sanitycheck
are_u_sure_about_that () {
## ask the user if they really want to proceed
printf '\n%s\n\n' "PROCEED WITH THESE VALUES? PLS BE SURE, (THIS IS FINAL.)"
printf '%s\n\n' "DEVICE: $device"
printf '%s\n\n' "SHRINK TO SIZE: $size"
printf '%s' "[y/n/r] "
read -r ynr; case $ynr in
y|Y)
create_firstboot_flag
tmp_unmount
fixfs
resizefs_p2
;; 
r|R) tmp_unmount; init ;;
*) tmp_unmount; exit ;;
esac
}


resizefs_p2 () {
printf '\n%s\n\n' "--> RESIZING SDCARD"
! sudo resize2fs "${device}${part2}" "${size}" && \
printf '\n%s\n' " --> RESIZE FAILED" && exit 1 || \
printf '%s\n' "--> RESIZE COMPLETE."
recreate_parttable
}


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
printf '%s\n' "--> SDCARD PARTITIONED"
sudo partprobe
create_img
}


create_img () {
get_start_and_end_sectors
printf '%s\n\n' "--> CREATING IMAGE WITH DD"
sudo dd if="${device}" of="$img" count="$p2_end"
printf '\n%s\n\n' "--> COMPRESSING IMAGE WITH XZ"
! sudo xz -kev8 "$img" && exit 1
exit 0
}


get_start_and_end_sectors () {
p2_start="$(sudo fdisk -l| grep "${device}${part2}" | tr -s ' '| cut -d ' ' -f 2)"
p2_end="$(sudo fdisk -l| grep "${device}${part2}" | tr -s ' '| cut -d ' '  -f 3)"
}


create_firstboot_flag () {
## creates firstboot flag (in ${tmpmnt2}/etc/.firstboot/firstboot)
## (if it doesn't already exists)
[ ! -f "${tmpmnt2}/etc/.firstboot/firstboot" ] && {
printf '\n%s\n' "--> CREATING FIRSTBOOT FLAG: ${tmpmnt2}/etc/.firstboot/firstboot"
sudo touch "${tmpmnt2}/etc/.firstboot/firstboot"
}
}


fixfs () {
printf '\n%s\n' "--> CHECKING FILESYSTEMS"
sudo fsck.fat "${device}${part1}"
sudo e2fsck -fy "${device}${part2}"
sync
}


tmp_mount () {
## mount the 1st partition of the chosen $device
printf '\n%s\n' "--> TRYING TO MOUNT: ${device}${part1}"
! sudo mount "${device}${part1}" "$tmpmnt1" && \
printf '%s\n' "--> ERROR: MOUNTING: ${device}${part1} TO: ${tmpmnt1} FAILED!" && exit 1
printf '%s\n' "--> SUCCESSFULLY MOUNTED: ${device}${part1} TO: ${tmpmnt1}"

## mount the 2nd partition of the chosen $device
printf '%s\n' "--> TRYING TO MOUNT: ${device}${part2}"
! sudo mount "${device}${part2}" "$tmpmnt2" && \
printf '%s\n' "--> ERROR: MOUNTING: ${device}${part2} TO: ${tmpmnt2} FAILED!" && exit 1
printf '%s\n' "--> SUCCESSFULLY MOUNTED: ${device}${part2} TO: ${tmpmnt2}"
}


tmp_unmount () {
## unmount the chosen $device
## check if "$tmpmnt1" is actually mounted
mount| grep -q "$tmpmnt1" && {
printf '\n%s\n' "--> TRYING TO UNMOUNT: ${device}${part1}"
! sudo umount "$tmpmnt1" && printf '%s\n' "--> ERROR: UNMOUNTING $tmpmnt1 FAILED!" && exit 1
printf '%s\n' "--> SUCCESSFULLY UNMOUNTED: ${device}${part1}"
}

## check if "$tmpmnt2" is actually mounted
mount| grep -q "$tmpmnt2" && {
printf '%s\n' "--> TRYING TO UNMOUNT: ${device}${part2}"
! sudo umount "$tmpmnt2" && printf '%s\n' "--> ERROR: UNMOUNTING $tmpmnt2 FAILED!" && exit 1
printf '%s\n' "--> SUCCESSFULLY UNMOUNTED: ${device}${part2}"
}
}


init
