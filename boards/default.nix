{ Tow-Boot }:

let
  inherit (Tow-Boot.nixpkgs) lib;

  # All directories with boards.
  dirs = builtins.filter
    (dir: builtins.pathExists (./. + "/${dir}/default.nix"))
    (builtins.attrNames (builtins.readDir ./.))
  ;

  # Same dirs as previously listed, but callPackage'd.
  importedDirs = map (dir: Tow-Boot.callPackage (./. + "/${dir}") { }) dirs;

  # Remove unwanted attributes coming from `callPackage`.
  cleanup = attrset: builtins.removeAttrs attrset [ "override" "overrideDerivation" ];

  # Given a list of attrsets, merge them all together.
  mergeAttrsets = lib.foldr (a: b: a // b) {};
in

# Merge all lists together
cleanup (mergeAttrsets importedDirs)
