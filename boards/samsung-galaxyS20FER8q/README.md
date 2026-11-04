# Samsung Galaxy S20 FE (R8Q)

## Device-specific notes

This experimental Tow-Boot port combines the working R8Q/SM8250 U-Boot
hardware support with Tow-Boot's curses menu and firmware identity. Both
source revisions are pinned and hash-checked. A local compatibility patch
adapts the menu to modern U-Boot APIs, handles phone Enter keys, and routes
interrupted autoboot to the menu.

The phone boots internal storage first (the existing userdata block mapping,
then UFS partitions), followed by microSD and USB storage. Modern U-Boot's
bootflow scanner looks for EFI fallback loaders, extlinux configurations, and
boot scripts. Global boot methods are excluded from these per-device scans
so they cannot silently override the selected storage.

Hold **Volume Down** during startup to enter the Tow-Boot menu. Use the volume
buttons to navigate and Power to select. Hold **Volume Up** during startup
to enter USB mass storage. The menu also provides USB serial, fastboot,
firmware console, reboot, and shutdown. Choose **USB serial console** before
**Firmware Console** if no physical serial interface is connected.

USB mass storage exposes the entire `scsi 0` UFS device for read/write access,
not just the Linux partition. Avoid host-side partitioning or formatting.
No bootloader installation or flashing is automated.

The default environment is read-only and EFI capsule firmware updates are
disabled. The phone retains Samsung's earlier boot stages. This is not a
replacement for the Qualcomm secure boot chain, and does not add Linux kernel
support or guarantee stock Android booting.

The older PinePhone blind UX assumes RGB LEDs, vibration, and eMMC. R8Q uses
the inherited display and phone-keyboard support instead; that legacy module
and splash logo are not enabled. Display, buttons, USB modes, UFS/microSD,
EFI/extlinux booting, and power control still need validation on real hardware.
The target remains excluded from release artifacts until that validation.
