Fedora
======

Notes specific to Fedora.

> *These notes are given as a best effort.*
> This is not an installation guide, only notes about possible issues.

* * *

Partitioning shared storage with the graphical installer
--------------------------------------------------------

Use your preferred tool to partition your disk as desired, make sure to include
an EFI system partition big enough.

In the installer, choose *Custom* and add mount points and format the
partitions you have created.

No testing with *Advanced-Custom (Blivet-GUI)* was done, but assuming it will
not re-write the partition table from scratch and not touch the firmware
partition, it may work as well.


Bootloader Installation
-----------------------

The following error may happen near the end of the installation:

> Failed to set new efi boot target. This is most likely a kernel or firmware bug.

This is a known limitation with *U-Boot* and *Tow-Boot*.

You can ignore this error and continue with the installation (**Yes**).

Additionally, the EFI bootloader shim appears not to work under the conditions.

> **NOTE** These manipulations were written by someone not familiar with
> Fedora. Please suggest better supported alternatives.

You will need to do the following manipulation in the ESP after the
installation.

```
$ sudo -i
# cd /mnt/sysroot/boot/efi/EFI/BOOT/
# mv BOOTAA64.EFI _BOOTAA64.EFI 
# cp /mnt/sysroot/boot/efi/EFI/fedora/grubaa64.efi BOOTAA64.EFI
```

This will install GRUB as the default fallback bootloader location. Note that
this means that updates to GRUB from Fedora may not apply as expected.

It may be preferable to, instead, install *rEFInd* at the fallback bootloader
location (`/boot/efi/EFI/BOOT/BOOTAA64.EFI`).
