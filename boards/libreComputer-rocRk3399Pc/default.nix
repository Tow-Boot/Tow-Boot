{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "Libre Computer";
    name = "Renegade Elite";
    identifier = lib.mkDefault "libreComputer-rocRk3399Pc";
    productPageURL = "https://libre.computer/products/rk3399/";
  };

  hardware = {
    soc = "rockchip-rk3399";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = lib.mkDefault "roc-pc-rk3399_defconfig";
    config = [
      # NOTE: applied as configs, since the patches only change the
      # non-mezzanine variant.
      (helpers: with helpers; {
        # https://patchwork.ozlabs.org/project/uboot/patch/20220902082444.83788-2-abbaraju.manojsai@amarulasolutions.com/
        USE_PREBOOT = yes;
        PREBOOT = freeform ''"usb start"'';
        # https://patchwork.ozlabs.org/project/uboot/patch/20220902082444.83788-3-abbaraju.manojsai@amarulasolutions.com/
        USB_OHCI_HCD = yes;
        USB_OHCI_GENERIC = yes;
        #SYS_USB_OHCI_MAX_ROOT_PORTS = freeform "2"; # Not in 2022.07; as #define
        # https://patchwork.ozlabs.org/project/uboot/patch/20220902082444.83788-4-abbaraju.manojsai@amarulasolutions.com/
        DM_RNG = yes;
        RNG_ROCKCHIP = yes;
        # https://patchwork.ozlabs.org/project/uboot/patch/20220902082444.83788-5-abbaraju.manojsai@amarulasolutions.com/
        ENV_SPI_MAX_HZ = option (freeform "30000000"); # requires env being in SPI.
        SF_DEFAULT_SPEED = freeform "30000000";
      })
    ];
    setup_leds = "led green:work on; led red:diy on";
  };
}
