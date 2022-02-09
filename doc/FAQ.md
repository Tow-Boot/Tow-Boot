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
the firmware. If the system requires shared storage, and can only start the
platform firmware from the SD card, the SD card must contain its firmware. This
will probably not work well for two different enough platforms.

Though, still assuming the operating system can boot on all the devices you
want, if there is dedicated storage for the firmware on all of them, it should
work fine. Up to one system with shared storage using the pre-built images.

If you craft your own image, you might be able to put more than one firmware
for shared storage, if the location the different SoC uses does not conflict.


Why isn't this upstream?
------------------------

There are four main reasons it could be. The first is easy: because I've not
gotten around to posting a patch for it yet. Please press us to it for these
kind of changes!

The second is that the implementation is more experimental than final. It is
good enough for *Tow-Boot*, but the implementation needs more finishing touches
and more testing before being sent upstream. Think of these changes as if it
was part of a "staging" workflow, first maturing here.

The third is for changes that go against the opinions of upstream. These may
be changes to default options, or opinionated changes made in an unacceptable
form for upstream. Generally speaking, those changes represent opinionated
user-experience changes.

Finally, the main fourth reason is for board enablement. Generally speaking
those changes are provided by or on behalf of the vendor, and it is not our job
to provide those upstream. We try to avoid board enablement that have not
already been sent to upstream.


Why use this instead of my distro's *U-Boot* build?
---------------------------------------------------

In this project's opinion, the distribution shouldn't be managing the firmware
used to boot the system.

Confusingly enough, *U-Boot* is **both** a firmware (think "BIOS") and a
bootloader (think "grub").

The firmware should be a basic constant on the system, with well-defined
semantics allowing either a bootloader or an operating system to start.

Should all the distributions *have to* build and manage all the BIOS for all
your boring `x86_64` machines too?


Why the *Tow-Boot* name?
------------------------

Because of the pun on towboats, and the upstream pun on
[U-Boat](https://en.wikipedia.org/wiki/U-boat).
