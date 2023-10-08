# This expression is used to produce the release artifacts.
# To build for a particular board, please refer to `default.nix` instead.

# This is a "clean" Nixpkgs. No overlays have been applied yet.
{ pkgs ? import ./nixpkgs.nix {} }:

let
  inherit (pkgs.lib)
    concatStringsSep
    filter
  ;

  anonymousEval = release-tools.evalFor {} {
    hardware.soc = "generic-aarch64";
  };

  # We're slightly cheating here
  version = "${anonymousEval.config.Tow-Boot.uBootVersion}-${anonymousEval.config.Tow-Boot.towBootIdentifier}";

  release-tools = import ./support/nix/release-tools.nix { inherit pkgs; };
in
  pkgs.runCommand "Tow-Boot.release.${version}" {
    inherit version;
  } ''
    mkdir -p $out
    PS4=" $ "

    ${concatStringsSep "\n" (builtins.map (eval: ''
      (
      echo " :: Packaging ${eval.config.device.identifier}"
      cp ${eval.build.archive} $out/${eval.build.archive.name}
      )
    '') release-tools.releasedDevicesEvaluations)}
  ''
