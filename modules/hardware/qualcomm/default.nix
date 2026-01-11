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
      qualcomm-sdm845.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when targeting Qualcomm Snapdragon 845 (SDM845).";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "qualcomm-sdm845"
      ];
    }
    (mkIf cfg.qualcomm-sdm845.enable {
      system.system = "aarch64-linux";

      Tow-Boot = {
        # Newer Qualcomm devices use UFS as storage
        # On bootloader unlocked devices we store image in "boot"
        firmwarePartition = {
          offset = 0;
          length = 16 * 1024 * 1024;
        };
        builder = {
          additionalArguments = {
            ARCH = "arm64";
          };
          installPhase = ''
            echo ":: Preparing Qualcomm SDM845 binaries..."
            (PS4=" $ "; set -x

            mkdir $out/binaries/dtb
            cp -v u-boot.bin $out/binaries/u-boot.bin

            if [ -f u-boot-nodtb.bin ]; then
              cp -v u-boot-nodtb.bin $out/binaries/
            fi

            for dtb in dts/upstream/src/arm64/qcom/sdm845-*.dtb; do
              [ -f "$dtb" ] && cp -v "$dtb" $out/binaries/dtb
            done

            if [ -f u-boot.itb ]; then
              cp -v u-boot.itb $out/binaries/
            fi
            )
          '';
        };
      };
    })
  ];
}
