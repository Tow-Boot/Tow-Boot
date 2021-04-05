builtins.trace ":: Tow-Boot build infrastructure" (

{ pkgs ? import ./nixpkgs.nix {} }:

let
  outputs = import ./boards.nix {
    inherit pkgs;
  };
  outputsCount = builtins.length (builtins.attrNames outputs);
in

# Starting here is "noise" intended to make `nix-build` invocations more
# user-friendly.
outputs // {
  # Strategic use of `pkgs` to force evaluation before any tracing happens.
  ___aaallIsBeingBuilt = builtins.trace (pkgs.lib.removePrefix "trace: " ''
    trace: +--------------------------------------------------+
    trace: | Notice: ${pkgs.lib.strings.fixedWidthString 3 " " (toString outputsCount)} outputs will be built.               |
    trace: |                                                  |
    trace: | You may prefer to build a specific output using: |
    trace: |                                                  |
    trace: |   $ nix-build -A vendor-board                    |
    trace: +--------------------------------------------------+
  '') null;
}
)
