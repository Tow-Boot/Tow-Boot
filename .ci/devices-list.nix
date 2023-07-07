# This expression is intended to be evaluated with `--json` for CI purposes.
let
  pkgs = import ../nixpkgs.nix {};
  release-tools = import ../support/nix/release-tools.nix { inherit pkgs; };
in
  release-tools.allDevices
