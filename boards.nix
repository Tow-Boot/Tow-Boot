{ pkgs }:

let
  #
  # Targets setup
  # =============
  #

  crossPackageSets = {
    aarch64-linux = pkgs.pkgsCross.aarch64-multiplatform;
    armv7l-linux  = pkgs.pkgsCross.armv7l-hf-multiplatform;
    i686-linux    =
      if pkgs.system == "x86_64-linux"
      then pkgs.pkgsi686Linux
      else pkgs.pkgsCross.gnu32
    ;
    x86_64-linux  = pkgs.pkgsCross.gnu64;
  };

  pkgsFor = wanted:
    if pkgs.system == wanted then pkgs
    else crossPackageSets.${wanted}
  ;

  aarch64 = pkgsFor "aarch64-linux";
  armv7l  = pkgsFor "armv7l-linux";
  i686    = pkgsFor "i686-linux";
  x86_64  = pkgsFor "x86_64-linux";
in

{
}
