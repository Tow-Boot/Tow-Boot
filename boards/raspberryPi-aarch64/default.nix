{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "Raspberry Pi";
    name = "Combined AArch64";
    identifier = "raspberryPi-aarch64";
  };

  hardware = {
    # Targets multiple broadcom SoCs
    soc = "generic-aarch64";
  };

  # Workaround for the builder being required even if actually unused.
  TEMP.legacyBuilder = _: null;

  # Directly call the builder
  # This build is not like any others.
  build.default = lib.mkForce (pkgs.Tow-Boot.callPackage ./builder.nix { });
}
