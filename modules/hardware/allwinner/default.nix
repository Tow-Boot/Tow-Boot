{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  inherit (config.hardware) mmcBootIndex;
  cfg = config.hardware.socs;
  allwinnerSOCs = [
    "allwinner-a64"
    "allwinner-h3"
    "allwinner-h5"
    "allwinner-h6"
  ];
  anyAllwinner = lib.any (soc: config.hardware.socs.${soc}.enable) allwinnerSOCs;
  anyAllwinner64 = anyAllwinner && config.system.system == "aarch64-linux";
  isPhoneUX = config.Tow-Boot.phone-ux.enable;
in
{
  options = {
    hardware.socs = {
      allwinner-a64.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Allwinner A64";
        internal = true;
      };
      allwinner-h3.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Allwinner H3";
        internal = true;
      };
      allwinner-h5.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Allwinner H5";
        internal = true;
      };
      allwinner-h6.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Allwinner H6";
        internal = true;
      };
    };
    hardware.allwinner = {
      crust = {
        defconfig = mkOption {
          type = types.str;
          description = ''
            `defconfig` to use for the crust firmware build.

            Defaults to the same name as the U-Boot defconfig.
          '';
        };
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = allwinnerSOCs;
    }
    (mkIf anyAllwinner {

      hardware.allwinner.crust = {
        defconfig = lib.mkDefault config.Tow-Boot.defconfig;
      };
      Tow-Boot = {
        diskImage = {
          # Reduce GPT size to fit the firmware.
          gpt.partitionEntriesCount = 48;
        };
        firmwarePartition = {
            offset = 16 * 512; # 8KiB into the image, or 16 × 512 long sectors
            length = 4 * 1024 * 1024; # Expected max size
          }
        ;
        builder.installPhase = ''
          cp -v u-boot-sunxi-with-spl.bin $out/binaries/Tow-Boot.$variant.bin
        '';
        installer.additionalMMCBootCommands = ''
          mmc bootbus ${mmcBootIndex} 1 0 0
          mmc partconf ${mmcBootIndex} 1 1 1
        '';
      };
    })
    (mkIf (anyAllwinner64) {
      Tow-Boot.builder.additionalArguments = {
        BL31 = "${pkgs.Tow-Boot.armTrustedFirmwareAllwinner}/bl31.bin";
        SCP = lib.mkDefault "${pkgs.Tow-Boot.crustFirmware { inherit (config.hardware.allwinner.crust) defconfig; }}/scp.bin";
      };
    })
    (mkIf cfg.allwinner-a64.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.allwinner-h3.enable {
      system.system = "armv7l-linux";
      Tow-Boot.config = [
        (helpers: with helpers; {
          CMD_POWEROFF = no;
        })
      ];
    })
    (mkIf cfg.allwinner-h5.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.allwinner-h6.enable {
      system.system = "aarch64-linux";
      Tow-Boot.builder.additionalArguments = {
        BL31 = lib.mkForce "${pkgs.Tow-Boot.armTrustedFirmwareAllwinnerH6}/bl31.bin";
      };
    })

    # Documentation fragments
    (mkIf (anyAllwinner && !isPhoneUX) {
      documentation.sections.installationInstructions =
        lib.mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          # Allwinner will prefer SD card always.
          startupConflictNote = "";
        })
      ;
    })
  ];
}
