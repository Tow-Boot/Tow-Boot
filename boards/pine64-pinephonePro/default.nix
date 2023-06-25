{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "PINE64";
    name = "Pinephone Pro";
    identifier = "pine64-pinephonePro";
    productPageURL = "https://www.pine64.org/pinephonepro/";
  };

  hardware = {
    soc = "rockchip-rk3399";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "pinephone-pro-rk3399_defconfig";
    phone-ux = {
      enable = true;
      blind = true;
      wip = {
        led_R = "led-red";
        led_G = "led-green";
        led_B = "led-blue";
        mmcSD   = "1";
        mmcEMMC = "0";
      };
    };
    config = [
      (helpers: with helpers; {
        BUTTON_GPIO = yes;
        BUTTON_ADC = yes;
        LED_GPIO = yes;
        VIBRATOR_GPIO = yes;
      })
      (helpers: with helpers; {
        USB_GADGET_MANUFACTURER = freeform ''"Pine64"'';
      })
      (helpers: with helpers; {
        CMD_POWEROFF = lib.mkForce yes;
      })
      (helpers: with helpers; {
        # Workarounds required for eMMC issues and current patchset.
        MMC_IO_VOLTAGE = yes;
        MMC_SDHCI_SDMA = yes;
        MMC_SPEED_MODE_SET = yes;
        MMC_UHS_SUPPORT = yes;
        MMC_HS400_ES_SUPPORT = yes;
        MMC_HS400_SUPPORT = yes;
      })
    ];
  };
  documentation.sections.installationInstructions = builtins.readFile ./INSTALLING.md;
}
