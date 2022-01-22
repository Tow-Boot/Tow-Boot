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
      rockchip-rk3399.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Rockchip RK3399";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "rockchip-rk3399"
      ];
    }
    (mkIf cfg.rockchip-rk3399.enable {
      system.system = "aarch64-linux";
      # XXX legacy builder support
      TEMP = {
        legacyBuilder = pkgs.Tow-Boot.rockchipRK3399;
      };
    })
  ];
}
