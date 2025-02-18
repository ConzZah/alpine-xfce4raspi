# ALPINE LINUX XFCE CUSTOM IMAGE FOR RASPBERRY PI by ConzZah

![414088407-54fdeb62-6226-47c9-8b6d-8668cc3409fd(1)(1)](https://github.com/user-attachments/assets/2fa70502-21da-45c2-9db3-b45a7e0e4944)
![414087952-78197726-51a4-4263-ba70-b886d2d02337(1)](https://github.com/user-attachments/assets/c4e559a2-916e-4260-a663-f49fc03d3ff9)

**This custom image provides Alpine Linux for Raspberry Pi (4 + 5) with fully configured xfce desktop**

### VERSION: Alpine aarch64 v3.21.3 // v0.0.2

## what you get:

- a fully configured xfce desktop environment, out of the box.
- basic system utils, ufw with defaults, network-manager, firefox with ublock, vlc, ffmpeg, fastfetch, pipewire, python etc.
- automatic resizing of your sdcard and generation of ssh keys on firstboot
- bash as main shell


## NOTES

**please be aware that:**

- this is in **BETA**
- i do this **because i have fun with it, i ain't getting paid bro.** if something breaks, let me know, and i'll see if i find time.


### COMPATIBILITY:

**- RASPBERRY PI 4 / 400**

**- RASPBERRY PI 5 / 500**


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

**(using rpi-imager does not work for some reason.)**

**================================================**

If you find a bug, or have a suggestion, don't hesitate to let me know.

**THANKS TO EVERYONE WRITING SOFTWARE ON/WITH/FOR ALPINE LINUX !!**


**Cheers, ConzZah**
