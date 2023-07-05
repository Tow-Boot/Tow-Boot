{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;

  cfg = config.hardware;
in
{
  imports = [
    ./allwinner
    ./amlogic
    ./rockchip
    ./raspberryPi
    ./generic.nix
  ];

  options = {
    hardware = {
      soc = mkOption {
        description = ''
          SoC for the system.

          This is used to assume default behaviour during the build.
        '';
        type = types.enum config.hardware.socList;
      };
      socList = mkOption {
        description = ''
          List of all valid SoC values.
        '';
        type = with types; listOf str;
        internal = true;
      };
      SPISize = mkOption {
        description = ''
          Size of the SPI Flash.
        '';
        default = null;
        type = with types; nullOr int;
      };
      mmcBootIndex = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Enables building the dedicated mmc boot partition variant.

          Enable only on platforms where an SPI flash is not available, or not guaranteed.
        '';
      };
      # Do not use generic SOCs unless used for specific requirements.
      socs = {
        generic-aarch64.enable = mkOption {
          type = types.bool;
          default = false;
          internal = true;
        };
      };
    };
  };
  config = mkMerge [
    {
      hardware.socList = [
        "generic-aarch64"
      ];
      hardware.socs."${cfg.soc}".enable = true;
    }
    (mkIf config.hardware.socs.generic-aarch64.enable {
      system.system = "aarch64-linux";
    })
  ];
}
