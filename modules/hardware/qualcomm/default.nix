{ config, lib, ... }:

{
  options.hardware.socs.qualcomm-sm8250.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable when SoC is Qualcomm SM8250.";
    internal = true;
  };

  config = lib.mkMerge [
    { hardware.socList = [ "qualcomm-sm8250" ]; }
    (lib.mkIf config.hardware.socs.qualcomm-sm8250.enable {
      system.system = "aarch64-linux";
    })
  ];
}
