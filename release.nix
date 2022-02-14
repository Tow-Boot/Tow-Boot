# This expression is used to produce the release artifacts.
# To build for a particular board, please refer to `default.nix` instead.

# This is a "clean" Nixpkgs. No overlays have been applied yet.
{ pkgs ? import ./nixpkgs.nix {} }:

let
  inherit (pkgs.lib)
    concatStringsSep
    filter
  ;

  evalFor = device: (
    import ./support/nix/eval-with-configuration.nix {
      inherit
        pkgs
        device
      ;
      #verbose = true;
      configuration = {
        # Special configs for imperative use only here
        system.automaticCross = true;
      };
    }
  );

  # We're slightly cheating here
  version =
    let info = (import ./modules/tow-boot/identity.nix).Tow-Boot; in
    "${info.releaseNumber}${info.releaseIdentifier}"
  ;

  keepEval = (eval: eval.config.device.inRelease);

  all-devices =
    builtins.filter
    (d: builtins.pathExists (./. + "/boards/${d}/default.nix"))
    (builtins.attrNames (builtins.readDir ./boards))
  ;

  evals = builtins.map (device: evalFor device) all-devices;
  releasedEvals = filter keepEval evals;
in
  pkgs.runCommandNoCC "Tow-Boot.release.${version}" {
    inherit version;
  } ''
    mkdir -p $out
    PS4=" $ "

    ${concatStringsSep "\n" (builtins.map (eval: ''
      (
      echo " :: Packaging ${eval.config.device.identifier}"
      cp ${eval.build.archive} $out/${eval.build.archive.name}
      )
    '') releasedEvals)}
  ''
