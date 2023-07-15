{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
  ;
  inherit (pkgs)
    fetchpatch
  ;

  tbPatch =
    rev: sha256:
    fetchpatch {
      url = "https://github.com/Tow-Boot/U-Boot/commit/${rev}.patch";
      inherit sha256;
    }
  ;
in
mkIf config.Tow-Boot.buildUBoot  
{
  # Fixes for stock U-Boot
  Tow-Boot.patches = [
    # sunxi: Use mmc_get_env_dev only if relevant
    (tbPatch "e1d686d0591e8fa95d5218d965ec3b0aa83c5d27" "sha256-u3LVyKJvx5QDMJig+blFF1nGnSbVdCEI7zDx8HvHBfA=")
  ];
}
