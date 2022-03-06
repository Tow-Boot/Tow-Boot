Variants
========

 - `noenv` does not save environment anywhere
 - `spi` saves the environment to the SPI device
 - `mmcboot` does not save environment anywhere


`noenv`
-------

Only the built-in environment is used, read-only. In other words, `saveenv`
does nothing useful.

This variant is to be used with shared firmware storage *retrofitted* with a
Tow-Boot installation. In other words, in a system that does not provide a
protective partition for the firmware.

This variant is also used to build the installer images, as it ensures no stray
environment will change the behaviour of the installer *when booted form the
embedded Tow-Boot*.

> **NOTE**: This variant is currently used on all shared firwmare storage
> installations. In other words, using the protective partition does not
> *currently* grant the ability to save the environment.


`spi`
-----

This variant is to be used on systems with SPI Flash as dedicated firmware
storage.


`mmcboot`
---------

This variant is to be used on systems with eMMC Hardware boot partitions
as dedicated firmware storage.



* * *


Upcoming changes
----------------

It is expected that two other types of variants will come in the future. They
will provide environment facilities for the shared firmware storage
installations with protective partitions.

One will save the environment at the end of the protective partition.

The other, spcecialized for the Raspberry Pi family of hardware, will save the
environment as a file on the Tow-Boot firmware partition.
