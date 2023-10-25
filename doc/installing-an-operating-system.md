Installing an Operating System
==============================

The general idea is to follow the generic UEFI instructions for ARM or AArch64.

Tow-Boot cannot write to EFI variables. Your operating system's documentation
may have guidance on that situation; if its bootloader is GRUB, the
`--removable` flag may help.

Refer to your operating system's documentation.


Linux
-----

### Distribution-specific details

> **NOTE**: If a distribution is missing from this list, it does not mean it
> will not work.

<!-- This list is **alphabetically ordered** -->

 - [Fedora](distributions/fedora.md)
 - [Manjaro](distributions/manjaro.md)
 - [NixOS](distributions/nixos.md)

