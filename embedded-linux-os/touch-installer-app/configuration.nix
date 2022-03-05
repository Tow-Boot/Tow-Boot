{ lib, pkgs, ... }:

{
  imports = [
    ./initramfs.nix
    ./tow-boot.nix
  ];

  boot.cmdline = [
    "vt.global_cursor_default=0"

    #                 BG                                 FG
    #                blk, red, grn, ylw, blu, mgt, cyn, wht, gry,bred,bgrn,bylw,bblu,bmgt,bcyn,bwht
    "vt.default_red=0x00,0xD0,0x00,0xB0,0x00,0xA0,0x4F,0xFF,0x99,0xFF,0x00,0xFF,0x00,0xFF,0x00,0xFF"
    "vt.default_grn=0x36,0x00,0xB0,0x66,0x00,0x00,0xB3,0xFF,0x99,0x00,0xFF,0xFF,0x00,0x00,0xFF,0xFF"
    "vt.default_blu=0x73,0x00,0x00,0x00,0xB0,0xB0,0xC5,0xFF,0x99,0x00,0x00,0x00,0xFF,0xFF,0xFF,0xFF"
  ];

  wip.kernel = {
    structuredConfig = with lib.kernel; {
      # Basic features needed that may be removed by tinyconfig
      BLOCK = yes;
      USB_SUPPORT = yes;
      USB = yes;
      USB_ANNOUNCE_NEW_DEVICES = no;

      # To lazily report status on display...
      FRAMEBUFFER_CONSOLE = yes;
      VT_CONSOLE = yes;

      # TODO: "USB gadget" feature
      USB_GADGET = yes;
      # Otherwise gadget battery may unexpectedly drain.
      # The default is `2`.
      USB_GADGET_VBUS_DRAW = freeform "500";

      # Minimize the size, as convenient
      MODULES = no;
      CC_OPTIMIZE_FOR_PERFORMANCE = no;
      CC_OPTIMIZE_FOR_SIZE = yes;

      # Networking options required for udev
      NET = yes;
      UNIX = yes;
    };
    features = {
      logo = true;
      printk = true;
      serial = true;
      vt = true;
      graphics = true;
    };
    logo = ./installer.png;
  };

  wip.stage-1.compression = lib.mkDefault "xz";
}
