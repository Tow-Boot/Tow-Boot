{ pkgs ? import ../nixpkgs.nix { } }:

let
  styles = pkgs.callPackage ./_support/styles { };
in

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
  cp --no-preserve=mode -r $src src
  find src/_support -name '*.md' -delete
  ruby ${./_support/converter}/main.rb src/ $out/
  cp -r ${styles} $out/styles
  cp $src/favicon.png $out/
  )
''

) { }
