{ pkgs ? import ../nixpkgs.nix { } }:

pkgs.callPackage (

{ runCommandNoCC, cmark-gfm, ruby }:

runCommandNoCC "Tow-Boot-documentation" {
  src = ./.;
  nativeBuildInputs = [
    cmark-gfm
    (ruby.withPackages (pkgs: with pkgs; [ nokogiri ]))
  ];
} ''
  export LANG="C.UTF-8"
  export LC_ALL="C.UTF-8"

  (PS4=" $ "; set -x
  ruby ${./_support/converter}/main.rb $src/ $out/
  )
''

) { }
