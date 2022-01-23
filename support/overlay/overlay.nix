final: super:

let
  inherit (final) lib;
in
{
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

    # The basic Tow-Boot builder
    buildTowBoot = callPackage ../builders/tow-boot { };

    inherit (callPackage ./arm-trusted-firmware { })
      armTrustedFirmwareAllwinner
      armTrustedFirmwareRK3399
      armTrustedFirmwareS905
    ;

    amlogicFirmware = callPackage ./amlogic-firmware { };

    gxlimg = callPackage ./gxlimg { };

    meson64-tools = callPackage ./meson64-tools { };

    mkScript = file: final.runCommandNoCC "out.scr" {
      nativeBuildInputs = [
        final.buildPackages.ubootTools
      ];
    } ''
      mkimage -C none -A arm64 -T script -d ${file} $out
    '';

    allwinnerArmv7 = armv7l.callPackage ../builders/allwinner-armv7 { };

    rockchipRK3399 = aarch64.callPackage ../builders/rockchip-rk3399 {
      TF-A = aarch64.armTrustedFirmwareRK3399;
    };

    amlogicGXL = aarch64.callPackage ../builders/amlogic-gxl {
      inherit (final.buildPackages.Tow-Boot) gxlimg;
    };

    amlogicG12 = aarch64.callPackage ../builders/amlogic-g12 {
      inherit (final.buildPackages.Tow-Boot) meson64-tools;
    };

    spiInstallerPartitionBuilder = callPackage ../builders/spi-installer { };

    imageBuilder = (callPackage ../image-builder {
      # Some acrobatics needed because splicing doesn't seem to work here :/
      make_ext4fs = final.buildPackages.callPackage ./make_ext4fs { };
    }).overrideScope'(self: super: {
      firmwarePartition =
        { firmwareFile
        , partitionOffset
        , partitionSize
        , sectorSize ? 512
        }: {
          name = "Firmware (Tow-Boot)";
          partitionLabel = "Firmware (Tow-Boot)";
          # In theory this shouldn't be static, every partition should have a
          # unique identifier, but that's not really possible here.
          partitionUUID = "CE8F2026-17B1-4B5B-88F3-3E239F8BD3D8";
          # https://github.com/ARM-software/ebbr/issues/84
          # For now, we're "owning" this GUID.
          partitionType = "67401509-72E7-4628-B1AF-EDD128E4316A";
          offset = partitionOffset * sectorSize;
          length = partitionSize;
          filename = firmwareFile;
          filesystemType = "EBBR-firmware";
        }
      ;
    });
  });
}
