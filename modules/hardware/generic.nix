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
    hardware.socs = {
      generic-x86_64.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when targeting generic x86_64.";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "generic-x86_64"
      ];
    }
    (mkIf cfg.generic-x86_64.enable {
      system.system = "x86_64-linux";
    })
  ];
}
