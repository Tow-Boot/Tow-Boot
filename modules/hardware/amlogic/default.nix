{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.hardware.socs;

  #
  # Resources for identifying families:
  # 
  #  - https://linux-meson.com/hardware.html#supported-wip-soc-families
  #

  amlogicG12 = lib.any (soc: config.hardware.socs.${soc}.enable) [
    "amlogic-a311d"
    "amlogic-s922x"
    "amlogic-s905x3" # technically an SM1 family member, but the boot process is identical to G12
  ];
  amlogicGXL = lib.any (soc: config.hardware.socs.${soc}.enable) [
    "amlogic-s805x"
  ];

  # amlogic families using sector 0x01 for the startup sequence *ugh*.
  amlogicMBR = lib.any (v: v) [
    cfg.amlogic-s905.enable # Not defined under a family yet due to ODROID-C2 weirness.
    amlogicG12
    amlogicGXL
  ];

  anyAmlogic = lib.any (v: v) [amlogicGXL amlogicG12];
  isPhoneUX = config.Tow-Boot.phone-ux.enable;
in
{
  options = {
    hardware.socs = {
      amlogic-a311d.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic A311D";
        internal = true;
      };
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
      amlogic-s905x3.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S905X3";
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
        "amlogic-a311d"
        "amlogic-s805x"
        "amlogic-s905"
        "amlogic-s905x3"
        "amlogic-s922x"
      ];
    }
    (mkIf cfg.amlogic-a311d.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.amlogic-s805x.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.amlogic-s905.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.amlogic-s905x3.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.amlogic-s922x.enable {
      system.system = "aarch64-linux";
    })

    (mkIf amlogicMBR {
      Tow-Boot = {
        diskImage = {
          partitioningScheme = "mbr";
        };
        firmwarePartition = {
          offset = 512; # 512 bytes into the image, or 1 × 512 long sectors
          length = 4 * 1024 * 1024; # Expected max size
        };
      };
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

            if [[ "$variant" == "mmcboot" ]]; then
              echo ":: Offsetting for direct mmcboot write"
              (PS4=" $ "; set -x
              mv -v Tow-Boot.bin Tow-Boot.bin.tmp
              dd if=/dev/zero of=offset.bin bs=512 count=1
              cat offset.bin Tow-Boot.bin.tmp > Tow-Boot.bin
              rm -v Tow-Boot.bin.tmp
              )
            fi

            echo " :: Installing..."
            cp -v Tow-Boot.bin $out/binaries/Tow-Boot.$variant.bin
          '';
        };
      };
    })
    (mkIf amlogicGXL {
      Tow-Boot = {
        builder = {
          nativeBuildInputs = [
            pkgs.buildPackages.Tow-Boot.gxlimg
          ];
          installPhase = ''
            echo ":: Merging with firmware blobs"
            (PS4=" $ "; set -x
            # Sign BL2
            python3 $FIPDIR/acs_tool.py $FIPDIR/bl2.bin ./bl2_acs.bin $FIPDIR/acs.bin 0
            sh $FIPDIR/blx_fix.sh \
              ./bl2_acs.bin \
              ./tmp.zero \
              ./tmp.bl2.zero.bin \
              $FIPDIR/bl21.bin \
              ./tmp.bl21.zero.bin \
              ./bl2_new.bin \
              bl2
            gxlimg -t bl2 -s bl2_new.bin bl2.bin.enc

            # Sign Bl3*
            sh $FIPDIR/blx_fix.sh \
              $FIPDIR/bl30.bin \
              ./tmp.zero \
              ./tmp.bl30.zero.bin \
              $FIPDIR/bl301.bin \
              ./tmp.bl301.zero.bin \
              ./bl30_new.bin \
              bl30
            gxlimg -t bl3x -c bl30_new.bin     bl30.bin.enc
            gxlimg -t bl3x -c $FIPDIR/bl31.img bl31.img.enc

            # Encrypt U-Boot
            gxlimg -t bl3x -c u-boot.bin u-boot.bin.enc
            gxlimg -t fip \
              --bl2 ./bl2.bin.enc \
              --bl30 ./bl30.bin.enc \
              --bl31 ./bl31.img.enc \
              --bl33 ./u-boot.bin.enc \
              ./gxl-boot.bin
            mv -v gxl-boot.bin Tow-Boot.bin
            )

            echo ":: Making USB boot files"
            (PS4=" $ "; set -x
            dd if=Tow-Boot.bin of=Tow-Boot.bin.usb.bl2 bs=49152 count=1
            dd if=Tow-Boot.bin of=Tow-Boot.bin.usb.tpl skip=49152 bs=1
            )

            echo " :: Installing..."
            cp -v Tow-Boot.bin         $out/binaries/Tow-Boot.$variant.bin
            cp -v Tow-Boot.bin.usb.bl2 $out/binaries/Tow-Boot.$variant.usb.bl2
            cp -v Tow-Boot.bin.usb.tpl $out/binaries/Tow-Boot.$variant.usb.tpl
          '';
        };
      };
    })

    # Documentation fragments
    (mkIf (anyAmlogic && !isPhoneUX) {
      documentation.sections.installationInstructions =
        lib.mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          startupConflictNote = ''

            > **NOTE**: The SoC startup order for Amlogic systems will
            > prefer *SPI*, then *eMMC*, followed by *SD* last.
            >
            > You may need to prevent default startup sources from being used
            > to install using the Tow-Boot installer image.

          '';
        })
      ;
    })
  ];
}
