GPT
===

This shared disk image strategy simply uses a GPT partition to hold the
firmware.

The firmware is installed to a discrete partition. The user must take care by
not removing said partition when setting partitions up.

> **NOTE**: The partition may end up unaligned, and it is by design. By default
> most GPT partition tools will start adding partitions to the 2048th sector
> (assuming 512 byte sectors).
>
> The partition can be placed to an earlier location with this scheme.


Partitioning safely
-------------------

**Do not** zero out the GPT.

**Use the existing GPT**, remove all but the firmware partition, if desired.
