# PINE64 Pinephone (A64)

## Device-specific notes

There is no display output for this device.


## Startup order conflicts

The Allwinner SoC used in the Pinephone (A64) will always prefer starting
the platform firmware (U-Boot) from SD card when available.

When using some pre-built distribution images, it may be desirable to neuter
the U-Boot that is baked into the image.

With the usual U-Boot setup for Allwinner, the easiest way to strip U-Boot
from an eMMC or SD image is by running the following command, taking care
to replace `[DEVICE]` with the device for the storage device.

```
 $ sudo dd if=/dev/zero of=/dev/[DEVICE] bs=8k seek=1 count=4
```

When running the command on the Pinephone (A64), *usually* the block device
for the SD card is `mmcblk0`, and the block device for the eMMC is `mmcblk2`.
You can use `lsblk` to look at the block devices available.

> **NOTE**: Make sure the operating system image has a baked-in U-Boot
> install before issuing the command, and that you are targeting the right
> storage device.
>
> Some distributions target UEFI boot, and use GPT. Issuing this command
> **will break the partition table**.

Finally, on distributions shipping U-Boot, it is prudent to disable the
package that provides the automatic upgrade facilities.

 - For Manjaro and Arch Linux, the package is called `uboot-pinephone`.


## Additional features

The phone can be started in *USB Mass Storage* mode by holding the *volume up*
button at startup before and during the second vibration. The LED will turn
blue if done successfully. In this mode, the phone will work like a USB drive
when connected to a host computer.

Booting an operating system from an SD card will require holding the *volume
down* button before and during the second vibration. When done successfully,
the LED will turn aqua.
