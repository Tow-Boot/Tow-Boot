{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;

  cfg = config.hardware;
in
{
  imports = [
    ./allwinner.nix
    ./amlogic.nix
    ./rockchip.nix
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
      # Do not use generic SOCs unless used for specific requirements.
      socs = {
        generic-aarch64 = mkOption {
          type = types.bool;
          internal = true;
        };
      };
    };
  };
  config = {
    hardware.socList = [
      "generic-aarch64"
    ];
    hardware.socs."${cfg.soc}".enable = true;
  };
}
