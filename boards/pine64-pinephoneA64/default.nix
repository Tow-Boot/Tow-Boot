{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "PINE64";
    name = "Pinephone (A64)";
    identifier = "pine64-pinephoneA64";
    productPageURL = "https://www.pine64.org/pinephone/";
    supportLevel = "supported";
  };

  hardware = {
    soc = "allwinner-a64";
    mmcBootIndex = "1";
  };

  Tow-Boot = {
    defconfig = "pinephone_defconfig";
    phone-ux = {
      enable = true;
      blind = true;
      wip = {
        led_R = "led-2";
        led_G = "led-1";
        led_B = "led-0";
        mmcSD   = "0";
        mmcEMMC = "1";
      };
    };
    config = [
      (helpers: with helpers; {
        BUTTON_GPIO = yes;
        BUTTON_SUN4I_LRADC = yes;
        LED_GPIO = yes;
        VIBRATOR_GPIO = yes;
      })
      (helpers: with helpers; {
        USB_MUSB_GADGET = yes;
        USB_GADGET_MANUFACTURER = freeform ''"Pine64"'';
      })
    ];
    touch-installer = {
      targetBlockDevice = "/dev/mmcblk2boot0";
    };
  };
  documentation.sections.installationInstructions = builtins.readFile ./INSTALLING.md;
}
