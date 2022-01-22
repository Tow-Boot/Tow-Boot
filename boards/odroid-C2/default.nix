{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "ODROID";
    name = "C2";
    identifier = "odroid-C2";
  };

  hardware = {
    soc = "amlogic-s905";
  };

  Tow-Boot = {
    defconfig = "odroid-c2_defconfig";
  };

  TEMP = {
    # Amlogic S905 / GXBB
    # This uses a bespoke build because while it's GXBB, the binaries from the
    # vendor are not as expected.
    legacyBuilder = lib.mkForce (pkgs.Tow-Boot.systems.aarch64.callPackage ./builder.nix);
    legacyBuilderArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/odroid-c2";
    };
  };
}
