{ config, lib, pkgs, ... }:

let
  pw = id: sha256: pkgs.fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };
in
{
  device = {
    manufacturer = "PINE64";
    name = "Pinephone (A64)";
    identifier = "pine64-pinephoneA64";
  };

  hardware = {
    soc = "allwinner-a64";
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
    patches = [
      ./0001-Enable-led-and-vibrate-on-boot-to-notify-user-of-boo.patch
      ./0001-HACK-button-sun4i-lradc-Provide-UCLASS_BUTTON-driver.patch

      # Fixes USB gadget mode enabled outside of defconfig for allwinner
      # https://patchwork.ozlabs.org/project/uboot/patch/20191127195602.7482-1-samuel@dionne-riel.com/
      (pw "1202024" "0c196zk1s3pq3wdv909sxmjgqpll2hwb817bpbghkfkyyknl96vg")
      ./0001-HACK-cmd-ums-Ensure-USB-gadget-is-probed-via-workaro.patch
    ];
  };
}
