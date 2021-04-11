Holey GPT
=========

This shared disk image strategy carves a hole before the GPT entries, in which
the boot firmware can be installed.

This makes the firmware totally invisible to the disk image, but comes at the
cost of it being out of sight, thus out of mind.

Carelessly erasing the GPT and starting from scratch will erase the firmware.


Partitioning safely
-------------------

**Do not** zero out the GPT.

**Use the existing GPT**, but remove all partitions if desired.
