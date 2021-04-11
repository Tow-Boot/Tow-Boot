Boards
======

This directory contains build instructions for all supported boards.


Implementation Details
----------------------

Board names here may differ from U-Boot naming. The scheme is as follows:

    "${vendor}-${boardName}"

 * Both identifiers are *camelCase'd*.
 * The vendor identifier is the same for all of their boards.
 * The board identifier *may* repeat the vendor name if it is part of the board name.
 * The board identifier is generally not shortened.
