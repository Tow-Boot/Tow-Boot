<div class="homepage-hero">

Tow-Boot
========


What is Tow-Boot?
-----------------

**Tow-Boot** a user-friendly, opinionated distribution of *U-Boot*, where there
is as few differences in features possible between boards, and a "familiar"
user interface for an early boot process tool.

The goal of Tow-Boot is to **make booting boring**.

</div>


Goals
-----

> **NOTE**: Some of these goals are work-in-progress, others may not be started.

### Simple and boring

Install firmware, boot distro. No other steps.


### "Normal" BIOS-like experience

On boards with dedicated storage for the firmware, the *Tow-Boot* build should
be independent from, and not care about the installed system media.

Update should be handled out-of-band (through a firmware update option in the
firmware, or from distro-independent systems like *fwupd*). The firmware is not
"owned" by the currently running distro. The firmware is not updated or changed
through package upgrades.

Having no bootable storage, or all blanked bootable storage should still show
a "useful" boot interface. (E.g. explaining what to do and giving some basic
information about the board)

Configuration should be handled through menu-based interfaces. Options changed
in the menu interface saved to the firmware storage.


### Boot modes

Support for generic mainline-based ARM distros as a first class citizen. Whether
they boot using UEFI (preferred), or extlinux-compatible boot.

See [`develop/distro.rst`](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/develop/distro.rst)
from *U-Boot* for all the boot modes that aim to be supported.


### Pretty and boring

A logo, instructions on how to to get to the firmware interface. That's it.

Serial output should stay as verbose as mainline *U-Boot* is.

The firmware interface is menu-driven. Though breaking out into hush is
supported for more involved needs.


### Unsurprising and boring

No needless board-specific or SoC-specific differences in builds.

Boot order is unsurprising: on shared storage, the storage from which the
currently running *Tow-Boot* is running is prioritized by default.

Bootable targets are listed in the menu driven interface.

<div class="homepage-acknowledgements">

Acknowledgements
----------------

This project was funded in part through the NGI PET Fund.
[Read more about it on NLnet's website](https://nlnet.nl/PET/).

<a href="https://nlnet.nl/NGI0/">
	<img src="images/NGI0_tag_black_mono.svg" alt="NGI0" />
</a>
</div>
