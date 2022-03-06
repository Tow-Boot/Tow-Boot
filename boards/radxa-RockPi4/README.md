# Radxa ROCK Pi 4 model A/B

## Device-specific notes

According to the [upstream SPI documentation](https://wiki.radxa.com/Rockpi4/hardware/spi_flash),
the SPI flash is only populated on board revisions V1.4 and later.

While the schematics denote `W25Q64FV` is used, all verified units came
with an `XT25F32B`.

If no flash is present, the user either needs to use the shared storage strategy,
or needs to manually solder on some pin-compatible SPI flash (`SOP8` footprint).
