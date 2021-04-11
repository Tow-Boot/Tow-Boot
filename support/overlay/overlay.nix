final: super:

let
  inherit (final) lib;
in
{
  Tow-Boot = lib.makeScope final.newScope (self:

  let
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

    # The basic Tow-Boot builder
    buildTowBoot = self.callPackage ../builders/tow-boot { };

    # Common builders
    allwinnerA64 = aarch64.callPackage ../builders/allwinner-a64 {
      TF-A = aarch64.nixpkgs.armTrustedFirmwareAllwinner;
    };

    rockchipRK399 = aarch64.callPackage ../builders/rockchip-rk3399 {
      TF-A = aarch64.nixpkgs.armTrustedFirmwareRK3399;
    };
  });
}
