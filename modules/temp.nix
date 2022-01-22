{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.hardware.socs;
in
{
  options = {
    TEMP = {
      legacyBuilder = mkOption {
        type = types.anything; # meh
      };
      legacyBuilderArguments = mkOption {
        type = with types; attrsOf anything; # meh
      };
    };
  };

  config = mkMerge [
    {
      TEMP = {
        legacyBuilderArguments = {
          postPatch = mkIf (config.Tow-Boot.setup_leds != null) ''
            substituteInPlace include/tow-boot_env.h \
              --replace 'setup_leds=echo\0' 'setup_leds=${config.Tow-Boot.setup_leds}\0'
          '';
          boardIdentifier = config.device.identifier;
          defconfig = config.Tow-Boot.defconfig;
          patches = config.Tow-Boot.patches;
          SPISize = config.hardware.SPISize;
          withSPI = config.hardware.SPISize != null;
        };
      };
      build = {
        default = config.TEMP.legacyBuilder config.TEMP.legacyBuilderArguments;
      };
    }
  ];
}
