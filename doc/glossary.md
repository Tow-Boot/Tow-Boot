Glossary
========

Terminology as used in the project.

* * *


Initial Boot Firmware
---------------------

The *Initial Boot Firmware* is a generic term used to describe the first thing
the CPU starts at boot time. On your typical `x86_64` system, it would be what
was previously called the *BIOS*. Now often diminutively called by the name
*EFI*. This is what initializes enough of the hardware so that the *operating
system* can start. Additionally, it often provides facilities for the user to
do basic configuration, and manage boot options.

In the ARM with SBCs landscape, **U-Boot** is the de facto solution for the
*Initial Boot Firmware*. Though *U-Boot* is confusingly, but rightly, often
referred to as a *Boot Loader*. *U-Boot* plays double duties often. It is
tasked with *initializing the hardware*, and often also used to handle *loading
and booting* the operating system.


Boot Loader
-----------

The *Boot loader* is a program which may or may not be distinct from the
*Initial Boot Firmware*, which is meant to load a start an *Operating System*.

*Boot loaders* are now commonly written following the *UEFI* spec. *GRUB*,
*rEFInd* and *systemd-boot* are examples of UEFI *boot loaders*.


Dedicated storage
-----------------

**Dedicated storage** is used when the *Tow-Boot* installation lives on a
location where it is not expected the target booted system would live.

Generally speaking, an SPI flash chip **is** *dedicated storage*.

A built-in eMMC, even if small, would be *shared storage*.


Shared storage
--------------

**Shared storage** is used when the *Tow-Boot* installation lives on the same
storage as the booted system.

While technically some say it wouldn't be *shared storage*, if the storage
where *Tow-Boot* is installed is also a bootable target, it is *shared storage*.
Even if the actually booted system lives entirely on another storage.

E.g. on a *Raspberry Pi*, reserving the whole SD card for the FAT32 partition
for the *Raspberry Pi* firmware files and for the *Tow-Boot* install, and
booting a GPT-formatted USB drive, *Tow-Boot* is considered to be installed as
**shared storage**.
