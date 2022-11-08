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
    patches = [
      #
      # Generic changes, not device specific
      #

      # Upstreamable
      ./0001-mtd-spi-nor-ids-Add-GigaDevice-GD25LQ128E-entry.patch

      # Non-upstreamable
      ./0001-HACK-Do-not-honor-Rockchip-download-mode.patch
      ./0001-rk8xx-poweroff-support.patch

      # Subject: [PATCH] phy: rockchip: inno-usb2: fix hang when multiple controllers exit
      # https://patchwork.ozlabs.org/project/uboot/patch/20210406151059.1187379-1-icenowy@aosc.io/
      (pkgs.fetchpatch {
        url = "https://patchwork.ozlabs.org/series/237654/mbox/";
        sha256 = "0aiw9zk8w4msd3v8nndhkspjify0yq6a5f0zdy6mhzs0ilq896c3";
      })

      #
      # Device-specific changes
      #

      ./0001-pine64-pinephonepro-device-enablement.patch
      ./0001-rk3399-pinephone-pro-add-smbios-info.patch

      # pinephone-pro: Perform PMIC setup on boot (increase input current limit)
      # https://xff.cz/git/u-boot/commit/?h=ppp&id=7f8238fd608290152b143322178a5be21a447dc1
      (pkgs.fetchpatch {
        url = "https://xff.cz/git/u-boot/patch/?id=7f8238fd608290152b143322178a5be21a447dc1";
        sha256 = "sha256-B3B6AQqiQ0NbdVZ4Xu1UOotCDJCZgJcYGJlQKrORb6U=";
      })
    ];
  };
  documentation.sections.installationInstructions = builtins.readFile ./INSTALLING.md;
}
