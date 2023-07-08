{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    types
  ;

  withMMCBoot = config.hardware.mmcBootIndex != null;

  withSPI = config.hardware.SPISize != null;

  firmwareMMCBootEval = config.helpers.composeConfig {
    config.Tow-Boot.variant = "mmcboot";
  };

  firmwareSPIEval = config.helpers.composeConfig {
    config.Tow-Boot.variant = "spi";
  };

  firmwareBootSDFirstEval = config.helpers.composeConfig {
    config.Tow-Boot.variant = "boot-installer";
  };
in
{
  options = {
    build = {
      default = mkOption {
        description = ''
          Default output for Tow-Boot.

          This contains the unarchived content of the `archive` output.
        '';
        type = types.package;
      };
      archive = mkOption {
        description = ''
          Archived Tow-Boot build.

          The unarchived content are available in the `default` output.
        '';
        type = types.package;
      };
      firmwareMMCBoot = mkOption {
        type = with types; nullOr package;
        default = null;
        internal = true;
      };
      firmwareSPI = mkOption {
        type = with types; nullOr package;
        default = null;
        internal = true;
      };
      firmwareBootSDFirst = mkOption {
        type = with types; nullOr package;
        default = null;
        internal = true;
        description = ''
          Used for installer image duties.

          **Do not expose to end-users.**
        '';
      };
    };
  };
  config = {
    build = {
      archive = pkgs.callPackage (
        { runCommand, Tow-Boot, name }:
          runCommand "${name}.tar.xz" {
            dir = name;
          } ''
            PS4=" $ "
          
            (
            set -x
            cp --no-preserve=mode,owner -r ${Tow-Boot} $dir
            tar -vcJf $out $dir
            )
          ''
        ) {
        Tow-Boot = config.build.default;
        name = "${config.device.identifier}-${config.build.default.version}";
      };

      default = pkgs.callPackage (
        { lib, runCommand, firmware, firmwareMMCBoot, firmwareSPI, sharedDiskImage, mmcBootInstallerImage, spiInstallerImage }:
        let
          inherit (lib) optionalString;
        in
        runCommand "Tow-Boot.${config.device.identifier}.${config.build.default.version}" {
          inherit (firmware) version;
        } ''
          mkdir -p $out/{binaries,config}
          cp -rt $out/binaries/ ${firmware}/binaries/*
          cp -rt $out/config/ ${firmware}/config/*
          cp ${sharedDiskImage} $out/shared.disk-image.img
          ${optionalString (firmwareMMCBoot != null) ''
            cp -rt $out/binaries/ ${firmwareMMCBoot}/binaries/*
            cp -rt $out/config/ ${firmwareMMCBoot}/config/*
            cp ${mmcBootInstallerImage} $out/mmcboot.installer.img
          ''}
          ${optionalString (firmwareSPI != null) ''
            cp -rt $out/binaries/ ${firmwareSPI}/binaries/*
            cp -rt $out/config/ ${firmwareSPI}/config/*
            cp ${spiInstallerImage} $out/spi.installer.img
          ''}
        ''
      ) {
        firmware = config.Tow-Boot.outputs.firmware;
        inherit (config.build)
          firmwareMMCBoot
          firmwareSPI
        ;
        sharedDiskImage = config.Tow-Boot.outputs.diskImage;
        mmcBootInstallerImage =
          (
            # Note: This has to use the `noenv` (default) variant!!
            #       The installer image *uses* the noenv binary.
            #       The `mmcboot` variant is an additional input used to build the
            #       installed *payload*.
            config.helpers.composeConfig {
              config = {
                Tow-Boot.installer.enable = true;
                Tow-Boot.installer.targetConfig = firmwareMMCBootEval.config;
              };
            }
          ).config.Tow-Boot.outputs.diskImage
        ;
        spiInstallerImage =
          (
            # Note: This has to use the `noenv` (default) variant!!
            #       The installer image *uses* the noenv binary.
            #       The `spi` variant is an additional input used to build the
            #       installed *payload*.
            config.helpers.composeConfig {
              config = {
                Tow-Boot.installer.enable = true;
                Tow-Boot.installer.targetConfig = firmwareSPIEval.config;
              };
            }
          ).config.Tow-Boot.outputs.diskImage
        ;
      };
      firmwareMMCBoot = mkIf withMMCBoot firmwareMMCBootEval.config.Tow-Boot.outputs.firmware;
      firmwareSPI = mkIf withSPI firmwareSPIEval.config.Tow-Boot.outputs.firmware;
      firmwareBootSDFirst = firmwareBootSDFirstEval.config.Tow-Boot.outputs.firmware;
    };
  };
}
