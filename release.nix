# This expression is used to produce the release artifacts.
# To build for a particular board, please refer to `default.nix` instead.

# This is a "clean" Nixpkgs. No overlays have been applied yet.
{ pkgs ? import ./nixpkgs.nix {} }:

let
  inherit (pkgs.lib)
    filterAttrs
    isDerivation
    mapAttrs
    mapAttrsToList
    concatStringsSep
  ;

  # This is what we're using to get our outputs.
  default = filterAttrs (k: v: isDerivation v)
    (import ./default.nix { pkgs = pkgs; silent = true; })
  ;

  keepPackage = (k: v: !(v ? internal && v.internal));
  releasedPackages = filterAttrs keepPackage default;

  # We can use the sandbox to gather some information.
  inherit (default) uBoot-sandbox;

  # For example, the version.
  inherit (uBoot-sandbox) version;
in

pkgs.runCommandNoCC "tow-boot-release-${version}" {
  inherit version;
} ''
  mkdir -p $out
  PS4=" $ "
  
  ${concatStringsSep "\n" (mapAttrsToList (attr: firmware: ''
    (
    echo
    echo ":: Packing-up ${attr}"
    dir=${attr}-${version}
    set -x
    cd $out/
    cp --no-preserve=mode,owner -r ${firmware} $dir
    tar -vcJf $dir.tar.xz $dir
    rm -r $dir
    )
  '') releasedPackages)}
''
