## Installation instructions

> **NOTE**: The SoC startup order for Rockchip systems will
> prefer *SPI*, then *eMMC*, followed by *SD* last.
>
> You may need to prevent default startup sources from being used
> to install using the Tow-Boot installer image.
>
> With the *Pinephone Pro*, starting with the *Explorer Edition*, this
> can be done by holding the *RE* button.
>
> For previous editions, read the vendor documentation for test points to use,
> or neuter installed *platform firmware* from eMMC and SPI in any other way.

### Installing to SPI (recommended)

By installing Tow-Boot to SPI, your *PINE64 Pinephone Pro* will be able
to start using standards-based booting without conflicting with the
operating system storage.

To do so, you will need to write the SPI installer image to a suitable
SD card.

```
# dd if=spi.installer.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
```

Once done, power-off your *Pinephone Pro*, remove its battery, and insert the
SD card in the SD card slot.

Put back the battery in the *Pinephone Pro*, and power it on.

> **NOTE**: Reminder that at this point you should be holding the RE button
> until the phone vibrates and the LED lights up red.

> **TIP**: It may be easier to connect the phone to a power source via USB
> instead of pressing the power button.

> **WARNING**: Make sure you are holding the *RE* button **before** either
> powering-on using the power button or by connecting to a power source.

When starting up with Tow-Boot, which the installer image use, the phone will
vibrate slightly and the LED will turn red. After a short moment, the LED
should turn yellow.

A few moments later the display will turn on with a blue colour, or will
directly boot to the installer GUI.

> Unless you know the battery is completely charged, it is recommended to
> connect the phone to a power source. Just in case.

In the installer GUI, select *“Install Tow-Boot to SPI”*. It is not
necessary to erase the storage before installing. Erasing the storage can be
used to uninstall Tow-Boot (or any other platform firmware installed to the
SPI partition).

Once installed, remove the installation media, and verify Tow-Boot starts from
power-on.


### Installing to shared storage

> **NOTE**: If a *platform firmware* (e.g. U-Boot) is installed to eMMC or to
> SPI, you will need to either hold the *RE* button, or uninstall them.

Using the shared storage strategy on the *Pinephone Pro* can be done by
writing the `shared.disk-image.img` to an SD card or directly to eMMC.

```
 # dd if=shared.disk-image.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
```
