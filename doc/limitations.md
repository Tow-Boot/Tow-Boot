Limitations
===========

No efivar manipulations in the OS
---------------------------------

This means that manipulating boot entries will not work.

For the time being, it is expected that the booted operating system will use
the default fallback location for the EFI bootloader, or that an additional
"stage" will be added by the end-user to scan and boot a bootloader (e.g.
rEFInd)
