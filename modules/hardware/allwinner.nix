{ config, lib, pkgs, ... }:

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
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "allwinner-a64"
        "allwinner-h3"
        "allwinner-h5"
      ];
    }
    {
      # XXX legacy builder support
      TEMP = mkIf cfg.allwinner-a64.enable {
        legacyBuilder = pkgs.Tow-Boot.allwinnerA64;
      };
    }
    {
      # XXX legacy builder support
      TEMP = mkIf cfg.allwinner-h3.enable {
        legacyBuilder = pkgs.Tow-Boot.allwinnerArmv7;
      };
    }
    {
      # XXX legacy builder support
      TEMP = mkIf cfg.allwinner-h5.enable {
        legacyBuilder = pkgs.Tow-Boot.allwinnerA64;
      };
    }
  ];
}
