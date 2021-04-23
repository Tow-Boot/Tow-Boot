FAQ
===

Can I install any Linux distribution?
-------------------------------------

Maybe.

The Linux distribution installer image has to support your hardware.

Additionally, the distribution has to provide either a U-Boot compatible image,
or a UEFI installer.

Using a UEFI installer, and installing as a UEFI system is the preferred
method.


So I can install to an SD card that boots in any `AArch64` devices?
-------------------------------------------------------------------

Yes and no.

First, the "any `AArch64` devices" has to assume that the operating system can
run on those devices. For this question, we assume the operating system does.

It all depends on whether the systems require dedicated or shared storage for
the firmware. If the system requires shared storage, and can only boot the
initial firmware from the SD card, the SD card must contain its firmware. This
will probably not work well for two different enough platforms.

Though, still assuming the operating system can boot on all the devices you
want, if there is dedicated storage for the firmware on all of them, it should
work fine. Up to one system with shared storage using the pre-built images.

If you craft your own image, you might be able to put more than one firmware
for shared storage, if the location the different SoC uses does not conflict.
