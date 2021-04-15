Allwinner A64 builder
=====================

Can be used to build the firmware and support files for any Allwinner A64 board
and "compatible" SoCs.

 - Allwinner A64
 - Allwinner H5

No customization option is provided as Allwinner boards are generally
homogeneous.


Outputs
-------

The firmware image, which can manually be embedded to a storage device

A pre-embedded disk image meant for usage with shared storage, using the
"holey GPT" strategy.

When `withSPI` is true, it also outputs an SPI installer image.
