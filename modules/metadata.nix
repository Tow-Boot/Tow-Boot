{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  inherit (config.device)
    identifier
  ;

  withMMCBoot = config.hardware.mmcBootIndex != null;
  withSPI = config.hardware.SPISize != null;
in
{
  options = {
    build = {
      device-metadata = mkOption {
        type = types.package;
        internal = true;
        description = ''
          The device-metadata output is used internally by the documentation
          generation to generate the per-device pages.

          Assume this format is fluid and will change.
        '';
      };
    };
  };

  config = {
    build = {
      device-metadata = pkgs.writeTextFile {             
        name = "${identifier}-metadata";                               
        destination = "/${identifier}.json";                           
        text = (builtins.toJSON {                                              
          device = {
            inherit (config.device)
              identifier
              name
              manufacturer
              productPageURL
            ;
            fullName = "${config.device.manufacturer} ${config.device.name}";
            supportLevel = config.documentation.supportLevelDescriptions."${config.device.supportLevel}";
          };
          hardware = {
            inherit (config.hardware)
              soc
            ;
            inherit
              withSPI
              withMMCBoot
            ;
          };
          Tow-Boot = {
            inherit (config.Tow-Boot)
              defconfig
            ;
          };
          system = {
            inherit (config.system)
              system
            ;
          };
          documentation = {
            inherit (config.documentation.sections)
              installationInstructions
            ;
          };
        });
      };
    };
  };
}
