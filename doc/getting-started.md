Getting Started
===============

There are two main general ways to install *Tow-Boot*. Installing to a dedicated
platform firmware storage media, if your board supports it, or installing
on shared storage.

To know whether your board supports the dedicated storage for the platform
firmware, consult the documentation for your board.

On most boards supporting dedicated storage, it is possible to install using
the shared storage strategy, but this is discouraged. The benefits of writing
the firmware to dedicated storage far outweighs the drawbacks compared to using
the shared storage strategy.

In all cases, once the firmware has been installed, continue to the
[*Installing an Operating System*](installing-an-operating-system.md) section
from this manual.


Dedicated Storage
-----------------

This will use the automated menu-driven installer. Installing manually is also
possible, but out of scope for this guide.

Learn about the CPU boot order of your board, and ensure no dedicated or shared
storage has priority over the one you're going to use. 

> **NOTE**: If another Platform Firmware is present on the dedicated
> storage for your board, it is possible that it will have priority.
>
> You may need to erase it, or do other manipulations on your board to skip it
> for a single boot.

After writing the firmware, the installer will report success, and depending,
either reboot on any key input, or allow you to go back to the main menu, for
the graphical installer.

Assuming the dedicated storage has priority, or that the SD card has been
removed, it should now be booting in Tow-Boot from the dedicated storage.

You can now install a Linux distribution, without having to care about keeping
the storage media formatted in a specific manner.


### For SPI

1. Write the `spi.installer.img` file to an SD card or another valid storage
   media for your particular board.
   ```shell-session
    # dd if=spi.installer.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
   ```
1. Boot the media on your board
1. Use the menu-driven interface to choose **Flash firmware to SPI**.


### For eMMC Boot

1. Write the `mmcboot.installer.img` file to an SD card or another valid storage
   media for your particular board.
   ```shell-session
    # dd if=mmcboot.installer.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
   ```
1. Boot the media on your board
1. Use the menu-driven interface to choose **Flash firmware to eMMC Boot**.


Shared storage strategy
-----------------------

This is called a *strategy* because we are making plans that we have to follow.

With this method, we write what amounts to a *template* disk image, which is
already formatted in a controlled manner. The partition table is likely to be
GPT formatted, but some SoC families force the use of MBR.

The disk will contain a partition, this partition serves to **protect** the
platform firmware. It is important to know that with almost all SoC
families you **cannot** move the partition. It may be possible to resize it,
but the size has been chosen to allow further expansion if needed.

1. Write the `shared.disk-image.img` file to an SD card or another valid storage
   media for your particular board.
   ```shell-session
    # dd if=shared.disk-image.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
   ```

1. Some partitioning tools require the secondary GPT to be at the end of the
   disk before attempting any operations. Grow the GPT partition to the physical
   size of the medium. (This operation is a no-op that forces a rewrite of the
   partition table.)
   ```shell-session
    # sfdisk --append /dev/XXX
   ```

1. Boot the media on your board

> **NOTE**: When installing your operating system, make sure that you do not
> re-create the partition table from scratch, only edit the existing one.
> The [*Installing an Operating System*](installing-an-operating-system.md)
> section from this manual will remind you.

Using the *shared storage* strategy, you can simulate *dedicated storage* by
**not** installing and using the storage media the platform firmware lives
on.


Serial 
------

Many `AArch64` devices do not come with a display or can be used in headless mode (as an example - a small home server which doesn't need a display).

In those cases, using serial to interact with the device can be required. Especially before your operating system of choice is loaded.

Tow-Boot uses the same baud rate for all platforms and devices: `115200`. This applies to all platforms, even those which generally default to another serial baud rate.

You can use the serial console software of your preference - `screen` , `picocom` , `minicom` and others.

### Examples for connecting with serial

Examples to connect to the device while installing or booting Tow-Boot from another device:

```shell-session
$ screen /dev/ttyUSB0 115200
...
Press Ctrl+a and K to exit
```

```shell-session
$ picocom /dev/ttyUSB0 -b 115200
...
Press Ctrl+a and Ctrl+x to exit
```

```shell-session
$ minicom -D /dev/ttyUSB0 -b 115200
...
Press Ctrl+a and X to exit
```

To learn more, read the [*Differences from U-boot*](differences-from-u-boot.md) section.


Building Tow-Boot
-----------------

This is not a *getting started* topic exactly. This is covered in the
*[Development Guide](development-guide.md)* section.
