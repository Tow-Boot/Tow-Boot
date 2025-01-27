final: super:

let
  inherit (final) lib;
in
{
  make_ext4fs = final.callPackage ./make_ext4fs { };

  Tow-Boot = lib.makeScope final.newScope (self:

  let
    inherit (self) callPackage;
    inherit (self.systems)
      aarch64
      armv7l
      i686
      x86_64
    ;
  in
  {
    # A reference to the package set.
    nixpkgs = final;

    # Systems supported by the Tow-Boot build infra.
    # Will resolve either to native builds, or cross-compilation, depending
    # on the system the build is evaluated on.
    systems =
      let
        crossPackageSets = {
          aarch64-linux = final.pkgsCross.aarch64-multiplatform;
          armv7l-linux  = final.pkgsCross.armv7l-hf-multiplatform;
          i686-linux    =
            if final.system == "x86_64-linux"
            then final.pkgsi686Linux
            else final.pkgsCross.gnu32
          ;
          x86_64-linux  = final.pkgsCross.gnu64;
        };

        pkgsFor = wanted:
          if final.system == wanted then final
          else crossPackageSets.${wanted}
        ;
        applyOverlay = wanted: ((pkgsFor wanted).extend(import ./overlay.nix)).Tow-Boot;
      in
    {
      # Applies this overlay on top of `pkgsCross` components we actually want.
      # `pkgs.extend()` does not apply the overlay on these other pkgs sets.
      aarch64 = applyOverlay "aarch64-linux";
      armv7l  = applyOverlay  "armv7l-linux";
      i686    = applyOverlay    "i686-linux";
      x86_64  = applyOverlay  "x86_64-linux";
    };

    inherit (callPackage ./arm-trusted-firmware { })
      armTrustedFirmwareAllwinner
      armTrustedFirmwareRK3328
      armTrustedFirmwareRK3399
      armTrustedFirmwareS905
      armTrustedFirmwareTools
    ;

    crustFirmware = final.callPackage ./crust-firmware {
      inherit (final.buildPackages)
        stdenv
        flex
        yacc
      ;
      or1k-toolchain = final.pkgsCross.or1k.buildPackages;
    };

    amlogicFirmware = callPackage ./amlogic-firmware { };

    gxlimg = callPackage ./gxlimg { };

    meson64-tools = callPackage ./meson64-tools { };

    uswid = final.python3Packages.callPackage ./uswid { };

    mkScript = file: final.runCommand "out.scr" {
      nativeBuildInputs = [
        final.buildPackages.ubootTools
      ];
    } ''
      mkimage -C none -A arm64 -T script -d ${file} $out
    '';
  });
}
