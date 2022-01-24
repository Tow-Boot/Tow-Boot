{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.hardware.socs;
  amlogicG12 = lib.any (soc: config.hardware.socs.${soc}.enable) [
    "amlogic-s922x"
  ];
in
{
  options = {
    hardware.socs = {
      amlogic-s805x.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S805X";
        internal = true;
      };
      amlogic-s905.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S905";
        internal = true;
      };
      amlogic-s922x.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S922X";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "amlogic-s805x"
        "amlogic-s905"
        "amlogic-s922x"
      ];
    }
    (mkIf cfg.amlogic-s805x.enable {
      system.system = "aarch64-linux";
      # XXX legacy builder support
      TEMP = {
        legacyBuilder = pkgs.Tow-Boot.amlogicGXL;
      };
    })
    (mkIf cfg.amlogic-s905.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.amlogic-s922x.enable {
      system.system = "aarch64-linux";
    })
    (mkIf amlogicG12 {
      Tow-Boot = {
        builder = {
          nativeBuildInputs = [
            pkgs.buildPackages.Tow-Boot.meson64-tools
          ];
          installPhase = ''
            echo " :: Merging with proprietary components..."
            (PS4=" $ "; set -x
            meson64-pkg --type bl30 --output bl30.pkg $FIPDIR/bl30.bin $FIPDIR/bl301.bin
            meson64-pkg --type bl2 --output bl2.pkg $FIPDIR/bl2.bin $FIPDIR/acs.bin
            meson64-bl30sig --input bl30.pkg --output bl30.30sig
            meson64-bl3sig  --input bl30.30sig --output bl30.3sig
            meson64-bl3sig  --input $FIPDIR/bl31.img --output bl31.3sig
            meson64-bl3sig  --input u-boot.bin --output bl33.3sig
            meson64-bl2sig  --input bl2.pkg --output bl2.2sig
            args=(
              --bl2 bl2.2sig
              --bl30 bl30.3sig
              --bl31 bl31.3sig
              --bl33 bl33.3sig

              --ddrfw1 $FIPDIR/ddr4_1d.fw
              --ddrfw2 $FIPDIR/ddr4_2d.fw
              --ddrfw3 $FIPDIR/ddr3_1d.fw
              --ddrfw4 $FIPDIR/piei.fw
              --ddrfw5 $FIPDIR/lpddr4_1d.fw
              --ddrfw6 $FIPDIR/lpddr4_2d.fw
              --ddrfw7 $FIPDIR/diag_lpddr4.fw
            )
            test -e $FIPDIR/aml_ddr.fw && args+=(--ddrfw8 $FIPDIR/aml_ddr.fw)
            test -e $FIPDIR/lpddr3_1d.fw && args+=(--ddrfw9 $FIPDIR/lpddr3_1d.fw)

            meson64-bootmk --output Tow-Boot.bin "''${args[@]}"
            )

            echo " :: Installing..."
            cp -v Tow-Boot.bin $out/binaries/Tow-Boot.$variant.bin
          '';
        };
      };
    })
  ];
}
