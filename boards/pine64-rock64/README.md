# PINE64 ROCK64

## Device-specific notes

There is no display output for this device.

The vendor no longer includes SPI Flash chip on recent units.

## Recovering from a bad SPI flash

The SPI Flash can be “tied-down” (disabled) and removed from the startup order
by connecting **pin 23** (`SPI_SCLK`) to **ground** (e.g. pin 25 or 39) on the
*Pi2-compatible* connector.

Refer to the upstream schematic for the pin descriptions:

 - http://files.pine64.org/doc/Pine%20A64%20Schematic/Pine%20A64%20Pin%20Assignment%20160119.pdf

You can install or erase the content of the SPI Flash by disconnecting the pins
once a proper Tow-Boot build is started.
