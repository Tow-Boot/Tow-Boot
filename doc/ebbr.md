EBBR Compliance
===============

This document describes how compliant and non-compliant this project is.

The specification is available here:

 * [Embedded Base Boot Requirements (EBBR) Specification](https://arm-software.github.io/ebbr/)

At the time of last updating this document the EBBR specification was at
version **2.0.0**.

> *Any compliance issues missing from this document means either a
> documentation bug, and  it should be added to this document, or a
> non-compliance issue that should preferably be fixed.*

* * *

Platform specific notes
-----------------------

### Allwinner

With shared storage, as allowed by *4.1.1 GPT partitioning*, reduces the
*NumberOfPartitionEntries* value to make the required offset (LBA16) available.


### Amlogic

With shared storage, as allowed by *4.1.1.1. MBR partitioning*, the partition
scheme is MBR only. LBA1 is used by the platform *Boot ROM*, which conflicts
with the GPT data structures.


### Raspberry Pi

Contrary to *4.1. Partitioning of Shared Storage* and *4.1.1. GPT partitioning*,
the shared storage disk images for the Raspberry Pi platforms use an hybrid
partitioning scheme.

In this scheme, the *protective MBR* presents the firmware partition in a way
the *Boot ROM* of these platforms can use. This is the only allowed use of the
*protective MBR*. End-users should only edit the GPT entries, and ignore the
existence of the *protective MBR*.

We are not strictly complying here mainly because it allows using the GPT and
UEFI semantics better on a platform where we can.
