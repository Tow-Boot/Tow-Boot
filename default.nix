builtins.trace ":: Tow-Boot build infrastructure" (

# This is a "clean" Nixpkgs. No overlays have been applied yet.
{ pkgs ? import ./nixpkgs.nix {} }:

# Break the cycle
let pkgs' = pkgs; in

let
  pkgs = import ./support/overlay { pkgs = pkgs'; };

  outputs = import ./boards { inherit (pkgs) Tow-Boot; };
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
