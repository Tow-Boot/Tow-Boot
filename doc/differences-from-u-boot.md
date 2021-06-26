Differences from U-Boot
=======================

Tow-Boot tries to stay in-line with how U-Boot works. This is to make the
process of changing back and forth less painful, if desired. It also helps with
upstreaming changes back into U-Boot.

This document lists the breaking changes compared to U-Boot.

* * *

Behaviour
---------

### Serial is always at 115200

U-Boot uses the vendor's *usual* serial baud rate. This is fine when trying to
stay compatible with the vendor's ecosystem and usual ways of doing.

This is problematic when working and documenting across different platforms.
Having the same software act differently because it is booted on a different
computer may be surprising.

This is why **115200** is the serial baud rate. To date, no platform was found
to be incompatible with this baud rate.
