# PINE64 Pinephone (A64)

## Device-specific notes

When using prebuilt distribution images it's wise to strip uBoot from the image.
With the use of prebuilt images on SD-Card it's mandatory to strip uBoot from it, as uBoot will otherwise interfere with Tow-boot and only boot from SD-Card.
To strip uBoot from a SD-Card installation I used the Gnome Disks utility, but any other should work as well.
1. Select the "Unused Space (32MB)" at the beginning of the SD-card.
2. Choose option "Format Partition" and make sure to select "Wipe". The filesystem doesn't really matter.
3. After formatting you can choose to delete the partition again as well, but that's up to you.
4. To make sure uBoot doesn't get reinstalled you need to remove the uboot package from the distro packages. (In Manjaro's case this package is called "uboot-pinephone")

To strip uBoot from the eMMC installation I used above mentioned procedure, but then eMMC mounted as block device throught Tow-boot.
How to do this is written under "Additional features"

There is no display output for this device.

## Additional features

The phone can be started in *USB Mass Storage* mode by holding the *volume up*
button at startup before and during the second vibration. The LED will turn
blue if done successfully. In this mode, the phone will work like a USB drive
when connected to a host computer.

Booting an operating system from an SD card will require holding the *volume
down* button before and during the second vibration. When done successfully,
the LED will turn aqua.
