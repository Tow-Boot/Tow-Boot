{ device ? null
, configuration ? { }
, silent ? false
, pkgs ? import ./nixpkgs.nix { }
}@args:

let
  all-devices =
    builtins.filter
    (d: builtins.pathExists (./. + "/boards/${d}/default.nix"))
    (builtins.attrNames (builtins.readDir ./boards))
  ;

  evalFor = device:
    import ./support/nix/eval-with-configuration.nix (args // {
      inherit device;
      inherit pkgs;
      verbose = true;
      configuration = {
        imports = [
          configuration
          (
            { lib, ... }:
            {
              # Special configs for imperative use only here
              system.automaticCross = true;
            }
          )
        ];
      };
    })
  ;

  outputs = builtins.listToAttrs (builtins.map (device: { name = device; value = evalFor device; }) all-devices);
  outputsCount = builtins.length (builtins.attrNames outputs);

  pkgs = import ./nixpkgs.nix {};
in

outputs // {
  ___aaallIsBeingBuilt = if silent then null else (
  builtins.trace (pkgs.lib.removePrefix "trace: " ''
    trace: +--------------------------------------------------+
    trace: | Notice: ${pkgs.lib.strings.fixedWidthString 3 " " (toString outputsCount)} outputs will be built.               |
    trace: |                                                  |
    trace: | You may prefer to build a specific output using: |
    trace: |                                                  |
    trace: |   $ nix-build -A vendor-board                    |
    trace: +--------------------------------------------------+
 '') null);
}
