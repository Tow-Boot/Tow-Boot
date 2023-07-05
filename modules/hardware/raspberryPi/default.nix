{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkMerge
    mkOption
    mkForce
    mkDefault
    types
    generators
    ;

  # generator is missing in current nixpkgs pinned version
  # copied from current nixpkgs
  toINIWithGlobalSection = {
    mkSectionName ? (name: lib.strings.escape ["[" "]"] name),
    mkKeyValue,
    listsAsDuplicateKeys ? false,
  }: {
    globalSection,
    sections,
  }:
    (
      if globalSection == {}
      then ""
      else
        (generators.toKeyValue {inherit mkKeyValue listsAsDuplicateKeys;} globalSection)
        + "\n"
    )
    + (generators.toINI {inherit mkSectionName mkKeyValue listsAsDuplicateKeys;} sections);

  cfg = config.hardware.socs;
  cfg_rpi = config.hardware.raspberryPi;
  anyRaspberryPi64 = lib.any (v: v) [cfg.raspberryPi-arm64.enable];

  configTxtType = with types; let
    valueType = nullOr (oneOf [bool str int]);
  in
    attrsOf valueType;

  # reports boolean as 1/0
  mkValueStringConfigTxt = value:
    if value == true
    then "1"
    else if value == false
    then "0"
    else generators.mkValueStringDefault {} value;

  # dont pass null values
  mkKeyValueConfigTxt = k: v:
    if v == null
    then ""
    else
      generators.mkKeyValueDefault {
        mkValueString = mkValueStringConfigTxt;
      } "="
      k
      v;

  toConfigTxt = g: f:
    toINIWithGlobalSection {
      mkKeyValue = mkKeyValueConfigTxt;
    } {
      globalSection = g;
      sections = f;
    };

  configTxt = pkgs.writeText "config.txt" ''
    # TowBoot summary:
    # firmwarePackage: ${cfg_rpi.firmwarePackage.name}
    # foundationKernel: ${cfg_rpi.foundationKernel.name}
    # mainlineKernel: ${cfg_rpi.mainlineKernel.name}
    # armstubsPackage: ${cfg_rpi.armstubsPackage.name}

    ${toConfigTxt cfg_rpi.configTxt.global {}}
    ${toConfigTxt {} (removeAttrs cfg_rpi.configTxt.filters ["all"])}
    ${toConfigTxt {} {inherit (cfg_rpi.configTxt.filters) all;}}
  '';
in {
  options = {
    hardware.socs = {
      raspberryPi-arm64.enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable when is Raspberry Pi 3b, Raspberry Pi 3b+, Raspberry Pi 4b,
          Raspberry Pi 400, Raspberry Pi CM 3, Raspberry Pi CM 3+,
          Raspberry Pi CM 4 or Raspberry Pi zero 2 w.
        '';
        internal = true;
      };
    };

    hardware.raspberryPi = {
      configTxt.global = mkOption {
        type = types.submodule {
          freeformType = configTxtType;
        };
        default = {};
        description = ''
          Configuration file instead of the BIOS that use Raspberry Pi,
          see <link xlink:href="https://www.raspberrypi.com/documentation/computers/config_txt.html"/>
          for supported values.
        '';
      };

      configTxt.filters = mkOption {
        type = types.attrsOf (types.submodule {
          freeformType = configTxtType;
        });
        default = {};
        description = ''
          Conditional filters for config.txt.
          See https://www.raspberrypi.com/documentation/computers/config_txt.html#conditional-filters
        '';
      };

      upstreamKernel = mkOption {
        type = types.bool;
        default = true;
        description = ''
          The firmware sets globally `os_prefix` to `upstream/` and also
          prefer upstream Linux names for DTBs.
        '';
      };

      # package overrides
      firmwarePackage = mkOption {
        type = types.package;
        default = pkgs.raspberrypifw;
      };
      armstubsPackage = mkOption {
        type = types.package;
        default = pkgs.raspberrypi-armstubs;
      };
      mainlineKernel = mkOption {
        type = types.package;
        default = pkgs.linuxPackages_latest.kernel;
      };
      foundationKernel = mkOption {
        type = types.package;
        default = pkgs.linuxPackages_rpi4.kernel;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "raspberryPi-arm64"
      ];
    }

    (mkIf cfg_rpi.upstreamKernel {
      hardware.raspberryPi.configTxt.global = {
        upstream_kernel = true;
        os_prefix = null;
        kernel = "Tow-Boot.noenv.bin";
      };
    })

    (mkIf cfg.raspberryPi-arm64.enable {
      system.system = "aarch64-linux";

      hardware.raspberryPi.configTxt = {
        global.os_prefix = mkDefault "foundation/";
        filters."all" = mkDefault {};
      };

      Tow-Boot = {
        config = [
          (helpers:
            with helpers; {
              # 64 MiB; the default unconfigured state is 4 MiB.
              SYS_MALLOC_LEN = freeform ''0x4000000'';
              CMD_POWEROFF = no;
              CMD_PAUSE = mkForce no;

              # As far as distro_bootcmd is aware, the raspberry pi can
              # have up to three mmc "devices"
              #   - https://source.denx.de/u-boot/u-boot/-/blob/v2022.07/include/configs/rpi.h#L134-137
              # To be fixed in a refresh of the raspberry pi configs.
              # This currently adds two bogus "SD" entries *sigh*.
              # It's not an issue upstream since there is no menu; the bootcmd simply tries
              # all options in order. The bogus entries simply fail.
              TOW_BOOT_MMC0_NAME = freeform ''"SD (0)"'';
              TOW_BOOT_MMC1_NAME = freeform ''"SD (1)"'';
              TOW_BOOT_MMC2_NAME = freeform ''"SD (2)"'';
            })
        ];

        patches = [
          ./0001-rpi_arm64_defconfig-enable-rtl8152.patch
          ./0001-configs-rpi-allow-for-bigger-kernels.patch
          ./0001-rpi-Copy-properties-from-firmware-dtb-to-the-loaded-.patch
        ];

        # The Raspberry Pi firmware expects a filesystem to be used.
        writeBinaryToFirmwarePartition = false;

        diskImage = {
          partitioningScheme = "mbr";
        };

        firmwarePartition = {
          partitionType = "0C";
          filesystem = {
            filesystem = "fat32";
            populateCommands = ''
              target="$PWD"

              ## rpi boot config
              # We assume that a user is customizing config.txt via a custom tow-boot build
              cp -v "${configTxt}" "$target/config.txt"

              ## rpi firmware / bootloader
              fwb="${cfg_rpi.firmwarePackage}/share/raspberrypi/boot"
              cp -vt "$target/" $fwb/bootcode.bin $fwb/fixup*.dat $fwb/start*.elf

              ## rpi firmware DTBs

              ## rpi4 armstubs
              cp -vt "$target/" "${cfg_rpi.armstubsPackage}/armstub8-gic.bin"

              ## mainline (kernel, dtbs, !overlays)
              mkdir -p "$target/upstream"
              cp -vt "$target/upstream/" \
                "${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin" \
                ${cfg_rpi.mainlineKernel}/dtbs/broadcom/bcm*rpi*.dtb

              ## foundation (kernel, dtbs, overlays)
              mkdir -p "$target/foundation"
              cp -vrt "$target/foundation" \
                "${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin" \
                "${cfg_rpi.firmwarePackage}/share/raspberrypi/boot/overlays" \
                $fwb/*.dtb

              # we don't actually need this since the FW distributes DTBs:
              #  ''${cfg_rpi.foundationKernel}/dtbs/broadcom/bcm*rpi*.dtb \
            '';

            # The build, since it includes misc. files from the Raspberry Pi Foundation
            # can get quite bigger, compared to other boards.
            size = 32 * 1024 * 1024;
            fat32 = {
              partitionID = "00F800F8";
            };
            label = "TOW-BOOT-FW";
          };
        };
        builder.installPhase = ''
          cp -v u-boot.bin $out/binaries/Tow-Boot.$variant.bin
        '';
      };
    })
    # Documentation fragments
    (mkIf anyRaspberryPi64 {
      documentation.sections.installationInstructions =
        mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          storage = "an SD card, USB drive (if the Raspberry Pi is configured correctly) or eMMC (for systems with eMMC)";
        });
    })
  ];
}
