{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    optionals
    versionOlder
    versionAtLeast
  ;
  inherit (pkgs)
    fetchpatch
  ;

  inherit (config.Tow-Boot)
    uBootVersion
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
  Tow-Boot.patches = []
  ++ optionals (versionOlder uBootVersion "2023.01") [
    # sunxi: Use mmc_get_env_dev only if relevant
    (tbPatch "e1d686d0591e8fa95d5218d965ec3b0aa83c5d27" "sha256-u3LVyKJvx5QDMJig+blFF1nGnSbVdCEI7zDx8HvHBfA=")
  ]
  ++ optionals (versionAtLeast uBootVersion "2023.01") [
    # sunxi: Use mmc_get_env_dev only if relevant
    (tbPatch "eb193c32c471a829a0b81c6a94f9bb9b9e392fb3" "sha256-K7p8gDJwoaTMdVgvfXC2l/u6dxnIoEBrD+yoXpvY3EY=")
  ]
  ;
}
