{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "PINE64";
    name = "Pinephone Pro";
    identifier = "pine64-pinephonePro";
  };

  hardware = {
    soc = "rockchip-rk3399";
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
        CMD_POWEROFF = lib.mkForce no;
      })
    ];
    patches = [
      # Basic pinephone pro enablement
      ./0001-pinephone-pro-support.patch

      # Sync DT with arbitrary DT from a linux checkout
      # This configures some necessary hardware nodes like LED, buttons and vibrator.
      ./0001-WIP-Mostly-sync-with-Linux-dts.patch

      # Fix volume keys
      ./0001-adc-rockchip-saradc-Implement-reference-voltage.patch
      ./0001-WIP-rk3399-pinephone-pro-Tweak-and-fix-keys-adc-valu.patch

      # Enable led and vibrate on boot to notify user of boot status
      ./0001-rk3399-Light-PPP-red-LED-and-vibrate-ASAP-during-boo.patch

      # Vibrator support
      ./0001-add-vibrator-and-gpio-vibrator.patch

      # Fix weird rockchip-isms in U-Boot
      # TODO: move into general rk3399 handling?
      ./0001-Tow-Boot-Do-not-honor-Rockchip-download-mode.patch

      # Add improper shutdown implementation
      # See also: https://patchwork.ozlabs.org/project/uboot/cover/1568880493-22962-1-git-send-email-zhangqing@rock-chips.com/
      ./0001-pmic-shutdown-rk3399.patch
      ./0001-HACK-implement-do_poweroff-for-rk8xx.patch

      # https://patchwork.ozlabs.org/project/uboot/patch/20210406151059.1187379-1-icenowy@aosc.io/
      (pkgs.fetchpatch {
        url = "https://patchwork.ozlabs.org/series/237654/mbox/";
        sha256 = "0aiw9zk8w4msd3v8nndhkspjify0yq6a5f0zdy6mhzs0ilq896c3";
      })

      # Work around issue with eMMC driver
      ./0001-HACK-rockchip_sdhci-Work-around-broken-mmc-set_ios_p.patch
    ];
  };
}
