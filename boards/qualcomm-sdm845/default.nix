{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkMerge
    mkIf
  ;
  inherit (config.Tow-Boot) buildUBoot;
in
{
  device = {
    manufacturer = "Qualcomm";
    name = "SDM845 Mobile Phones";
    identifier = "qualcomm-sdm845";
    productPageURL = "https://www.qualcomm.com/products/mobile/snapdragon/smartphones/snapdragon-8-series-mobile-platforms/snapdragon-845-mobile-platform";
    supportLevel = "experimental";
  };

  hardware = {
    soc = "qualcomm-sdm845";
  };

  Tow-Boot = {
    buildUBoot = true;
    uBootVersion = lib.mkForce "2026.01";
    defconfig = "qcom_defconfig";
    variant = lib.mkDefault "androidboot";

    patches = lib.mkForce [];

    phone-ux = {
      enable = true;
      blind = true;
      wip = {
        # LED configuration depends on specific device
        # These are placeholders and should be adjusted per device
        led_R = "led-red";
        led_G = "led-green";
        led_B = "led-blue";
        mmcSD   = "1";
        mmcEMMC = "0";
      };
    };
    config = mkMerge [
      [(helpers: with helpers; {
        # Fix TEXT_OFFSET for ABL bootloader validation
        # ABL on newer Android versions (Q/R) validates TEXT_OFFSET = 0x00080000
        TEXT_BASE = option (freeform "0x80080000");

        HAVE_SYS_UBOOT_START = option yes;

        # Disable framebuffer clear to avoid distorting U-Boot output
        NO_FB_CLEAR = no;

        # Mark as optional to allow build with warnings instead of errors
        MSM_SMESM = option yes;
        DTB_RESELECT = option yes;

        # Ensure USB gadget manufacturer is set
        USB_GADGET_MANUFACTURER = option (freeform ''"Qualcomm"'');
      })]
      # Requires Tow-Boot patches - make optional for stock U-Boot base
      (mkIf (!buildUBoot) [(helpers: with helpers;{
        BUTTON_GPIO = option yes;
        LED_GPIO = option yes;
      })])
    ];
    touch-installer = {
      targetBlockDevice = "/dev/sda";
    };
  };
}
