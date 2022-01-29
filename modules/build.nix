{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;

  withSPI = config.hardware.SPISize != null;

  firmwareSPIEval = config.helpers.composeConfig {
    config.Tow-Boot.variant = "spi";
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
    };
  };
  config = {
    build = {
      archive = pkgs.callPackage (
        { runCommandNoCC, Tow-Boot, name }:
          runCommandNoCC "${name}.tar.xz" {
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
        { lib, runCommandNoCC, firmware, firmwareSPI, sharedDiskImage, spiInstallerImage }:
        let
          inherit (lib) optionalString;
        in
        runCommandNoCC "Tow-Boot.${config.device.identifier}.${config.build.default.version}" {
          inherit (firmware) version;
        } ''
          mkdir -p $out/{binaries,config,source}
          cp -rt $out/binaries/ ${firmware}/binaries/*
          cp -rt $out/config/ ${firmware}/config/*
          cp -rt $out/source/ ${firmware.source}/*
          cp ${sharedDiskImage} $out/shared.disk-image.img
          ${optionalString (firmwareSPI != null) ''
            cp -rt $out/binaries/ ${firmwareSPI}/binaries/*
            cp -rt $out/config/ ${firmwareSPI}/config/*
            cp -rt $out/source/ ${firmwareSPI.source}/*
            cp ${spiInstallerImage} $out/spi.installer.img
          ''}
        ''
      ) {
        firmware = config.Tow-Boot.outputs.firmware;
        firmwareSPI =
          if withSPI
          then firmwareSPIEval.config.Tow-Boot.outputs.firmware
          else null
        ;
        sharedDiskImage = config.Tow-Boot.outputs.diskImage;
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
    };
  };
}
