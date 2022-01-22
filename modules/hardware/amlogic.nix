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
      amlogic-s805x.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S805X";
        internal = true;
      };
      amlogic-s905.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S905";
        internal = true;
      };
      amlogic-s922x.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Amlogic S922X";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "amlogic-s805x"
        "amlogic-s905"
        "amlogic-s922x"
      ];
    }
    (mkIf cfg.amlogic-s805x.enable {
      system.system = "aarch64-linux";
      # XXX legacy builder support
      TEMP = {
        legacyBuilder = pkgs.Tow-Boot.amlogicGXL;
      };
    })
    (mkIf cfg.amlogic-s905.enable {
      system.system = "aarch64-linux";
    })
    (mkIf cfg.amlogic-s922x.enable {
      system.system = "aarch64-linux";
      # XXX legacy builder support
      TEMP = {
        legacyBuilder = pkgs.Tow-Boot.amlogicG12;
      };
    })
  ];
}
