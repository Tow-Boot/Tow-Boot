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
  nxpSOCs = [
    "nxp-imx8qm"
  ];
  anyNXP = lib.any (soc: config.hardware.socs.${soc}.enable) nxpSOCs;
  isPhoneUX = false;
in
{
  options = {
    hardware.socs = {
      nxp-imx8qm.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable when SoC is NXP i.MX8QuadMax";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = nxpSOCs;
    }
    (mkIf anyNXP {
      Tow-Boot = {
        # https://community.nxp.com/t5/i-MX-Processors-Knowledge-Base/i-MX8-Boot-process-and-creating-a-bootable-image/ta-p/1101253
        # the same as dd if=flash.bin of=/dev/sd[x] bs=1k seek=32
        firmwarePartition = {
          offset = 32 * 1024; # 32KiB into the image, or 64 × 512 long sectors, or 0x8000
          length = 8 * 1024 * 1024; # Let's have some room for possible FW size change
        };
      };

    })
    (mkIf cfg.nxp-imx8qm.enable {
      system.system = "aarch64-linux";
      Tow-Boot.builder.additionalArguments = {
        BL31 = "${pkgs.Tow-Boot.armTrustedFirmwareIMX8QM}";
        FWDIR = "${pkgs.Tow-Boot.imx8qmFirmware}";
      };
      Tow-Boot.config = [
          (helpers: with helpers; {
            # Enable EFI support
            CMD_BOOTEFI = yes;
            EFI_LOADER = yes;
            FIT = yes; #for BOOTM_EFI
            BOOTM_EFI = yes;
            CMD_BOOTEFI_HELLO = yes;
            CMD_BOOTEFI_SELFTEST = yes;
            DM_DEVICE_REMOVE = no;
            TOW_BOOT_MENU = yes;
            TOW_BOOT_MENU_CTRL_C_EXITS = yes;
            DISTRO_DEFAULTS = yes;
          })
        ];
    })

    # Documentation fragments
    (mkIf (anyNXP && !isPhoneUX) {
      documentation.sections.installationInstructions =
        lib.mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          # Assumed device-dependent as it is configurable:
          #  - https://community.nxp.com/t5/i-MX-Processors-Knowledge-Base/i-MX8-Boot-process-and-creating-a-bootable-image/ta-p/1101253
          startupConflictNote = ''

            > **NOTE**: The SoC startup order for NXP systems will be device-dependent.
            >
            > You may need to prevent default startup sources from being used
            > to install using the Tow-Boot installer image.

          '';
        })
      ;
    })
  ];
}
