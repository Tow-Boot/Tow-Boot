{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;

  cfg = config.hardware.socs;
  starFiveSOCs = [ "starfive-jh7100" ];
  anyStarFive = lib.any (soc: config.hardware.socs.${soc}.enable) starFiveSOCs;
in
{
  options = {
    hardware.socs = {
      starfive-jh7100.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is StarFive JH7100";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = starFiveSOCs;
    }
    (mkIf anyStarFive {
      system.system = "riscv64-linux";

      Tow-Boot = {
        defconfig = "starfive_jh7100_visionfive_smode_defconfig";

        src = pkgs.fetchFromGitHub {
          owner = "NickCao";
          repo = "u-boot-starfive";
          rev = "ac75aa54020412a83b61dad46c5ea15e7f9f525c";
          sha256 = "1idh5k1479znp24rrfa0ikgk6iv5h80zscqhi6yv5ah4czia3ip3";
        };

        builder.additionalArguments = {
          secondBoot = "${pkgs.buildPackages.Tow-Boot.jh7100-secondBoot}/${pkgs.buildPackages.Tow-Boot.jh7100-secondBoot.name}.bin";
          ddrinit = "${pkgs.buildPackages.Tow-Boot.jh7100-ddrinit}/${pkgs.buildPackages.Tow-Boot.jh7100-ddrinit.name}.bin";
        };

        builder = {
          installPhase = ''
            ls -al
          '';
        };
      };
    })

    # Documentation fragments
    (mkIf (anyStarFive) {
      documentation.sections.installationInstructions =
        lib.mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          # StarFive will prefer SD card always.
          startupConflictNote = "";
        })
      ;
    })
  ];
}
