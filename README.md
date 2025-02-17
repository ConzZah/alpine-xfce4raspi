# ALPINE LINUX XFCE CUSTOM IMAGE FOR RASPBERRY PI by ConzZah

This custom image provides Alpine Linux for Raspberry Pi (4) with fully configured xfce desktop

### VERSION: Alpine aarch64 v3.21.3 // v0.0.1 ( INITIAL RELEASE )


## what you get:

- a fully configured xfce desktop environment, out of the box.
- basic system utils, ufw with defaults, network-manager, firefox with ublock, vlc, ffmpeg, fastfetch, pipewire, python etc.
- automatic resizing of your sdcard and generation of ssh keys on firstboot
- bash as main shell


## NOTES

### general:

**please be aware that:**

- this is in **BETA**
- i do this **because i have fun with it, i ain't getting paid bro.** if something breaks, let me know, and i'll see if i have the time.


### !! COMPATIBILITY !!:

**- RASPBERRY PI 4 / 400**

**(an image for raspi 5 is in the works, which i will post when it's done.)**


### firstboot:
on first booting the system, it automatically generates new ssh keys and also **reboots once** to finish resizing your sd-card.

**don't be alarmed, this is expected.**


### DEFAULT PASSWORD: 123
**( ^ PLS CHANGE AFTER LOGIN ^ )**


### DEFAULT KEYMAP & TIMEZONE: German

### DEFAULT SYSTEM LANGUAGE: English

## FLASHING: use gnome-disks 

- get literally any micro sdcard **(min: 4gb)**
- choose "Restore Disk Image"
- navigate to the image
- flash image to sdcard
- done

**(using rpi-imager does not for some reason.)**

**================================================**

This is the initial release, so expect bugs.
if you find one, or have a suggestion, 
don't hesitate to let me know.

**THANKS TO EVERYONE WRITING SOFTWARE ON/WITH/FOR ALPINE LINUX !!**


**Cheers, ConzZah**
