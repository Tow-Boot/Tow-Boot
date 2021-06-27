Firmware storage map
====================

This document serves to show where things are written to on the different
backing storage media.

> **NOTE**: While this documents environment with shared storage media, it is
> not currently supported by any platforms. Though the allowances are put in
> place to ensure we can in the future.


Overview
--------

Tow-Boot is intended to be installed to either a dedicated storage media (e.g.
SPI Flash) or as a discrete partition within the shared media.

In either case, the more than strictly the firmware is stored.

The following map serves to represent on most platforms\*. The exact details
of the map, the size, and where it is stored will differ, but the general
idea is the same.

> \*: Some platforms, e.g. the Raspberry Pi family of hardware, does not follow
> this convention.

```
|             \\             |      //      |      896 KiB      | 128 KiB |
|-------------//-------------|      \\      | <unused reserved> |   env   |
|             \\             |      //      |----------- 1 MiB -----------|
| ( Platform-specific span ) |  ( Unused )  |    ( Tow-Boot specific)     |
```

This is a simplified overview.


The **Platform-specific span** holds the firmware as loaded by the platform's
Boot ROM. With most platforms, this is a specially formatted header, maybe
some platform-specific firmware files, which serves to load the SPL, which
in turn loads the trustzone implementation, then going back to the SPL,
which finally loads the actual firmware.

In other words, the *Platform-specific span* generally holds the entire
firmware implementation.

Next is an **Unused** span. This takes the *remainder* of the space. This
space is *currently unused*, but expect the firmware code to grow and use that
space.

Finally, the **Tow-Boot specific** span. This span is *reserved* for Tow-Boot
use. It is found at the very end of the firmware storage media (or the
partition). This span is further divided. 896KiB have been set aside in case
it is ever needed. 128 KiB is then used to hold the environment.

Nothing is set in stone. If a platform requires to encroach on the unused
reserved space, we will change things.


### Rockchip (MMC)

On Rockchip platform, using the shared boot media (installed to SD or eMMC),
the map for the *Platform-specific span* looks like the following:

```
LBA : 0x00  \\  0x22  //  0x40         // 0x4000           \\ 0x5840         0x6040
       |----//---|----\\---|-----------\\--|---------------//--|--------------|
       | [ GPT ] | (empty) | idbloader //  | firmware.itb  \\  |  (reserved)  |
       |    \\   |    //   | ============ Firmware partition ================ |
```

The partition is 12MiB. Though most of what is found before `0x4000` is mostly
wasted space currently.

The reserved span looks like this:

```
byte: 0xb08000            0xbe8000  0xc08000
LBA : 0x5840              0x5f40    0x6040
       |-----------------------------|
       |      896 KiB      | 128 KiB |
       | <unused reserved> |   env   |
       |----------- 1 MiB -----------|
       |    ( Tow-Boot specific)     |
```

The environment is found in `0xbe8000` up to and excluding `0xc08000`


Minimum requirements
--------------------

While the firmware is currently smaller than that, the minimum requirement is
**4 MiB**. This is the size used by the discrete protective partition. This
means that there is up to 3 MiB reserved for Tow-Boot and 

Installation on SPI Flash bigger is, obviously, supported. In those cases the
environment is still at the very end of the storage media.
