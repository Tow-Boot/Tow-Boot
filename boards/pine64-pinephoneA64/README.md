# PINE64 Pinephone (A64)

## Device-specific notes

When using prebuilt distribution images it's wise to strip uBoot from the image.
With the use of prebuilt images on SD-Card it is mandatory to strip uBoot from it, as uBoot will otherwise interfere with Tow-boot and only boot from SD-Card.

The easiest way to strip uBoot from any installation (either eMMC or SD-Card) is by using the following dd command:
"sudo dd if=/dev/zero of=/dev/[DEVICE] bs=8k seek=1 count=4", where you have to replace [DEVICE] with the relevant device name.
[DEVICE] can be found using the "lsblk" command, which most probably will output mmcblk0 for SD-Card and mmcblk2 for eMMC, but nonetheless issue the command just to be sure.
As a last step it is wise to wipe the relevant pinephone uboot package from your distro image.
For Manjaro and Arch the package is called uboot-pinephone.

There is no display output for this device.

## Additional features

The phone can be started in *USB Mass Storage* mode by holding the *volume up*
button at startup before and during the second vibration. The LED will turn
blue if done successfully. In this mode, the phone will work like a USB drive
when connected to a host computer.

Booting an operating system from an SD card will require holding the *volume
down* button before and during the second vibration. When done successfully,
the LED will turn aqua.
