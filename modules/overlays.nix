# Simply imports our overlay in Nixpkgs
{
  nixpkgs.overlays = [
    (import ../support/overlay/overlay.nix)
  ];
}
