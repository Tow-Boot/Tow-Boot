{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "U-Boot";
    name = "Sandbox";
    identifier = "uBoot-sandbox";
  };

  hardware = {
    # TODO: support running on other architectures
    soc = "generic-x86_64";
  };

  Tow-Boot = {
    defconfig = "sandbox_defconfig";
    patches = [
      ./0001-sandbox-Force-window-size.patch
    ];
    config = [
      (helpers: with helpers; {
        AUTOBOOT_MENUKEY = lib.mkForce (option no);
        AUTOBOOT_USE_MENUKEY = lib.mkForce (option no);
      })
    ];
    builder = {
      buildInputs = [
        pkgs.SDL2
        pkgs.perl
      ];
      # TODO: Add helper bin to start with dtb file
      installPhase = ''
        rmdir $out/binaries
        mkdir -p $out/libexec
        cp -v u-boot $out/libexec/tow-boot
        cp -v u-boot.dtb $out/tow-boot.dtb
      '';
    };
  };
}
