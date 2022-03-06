{ pkgs ? import ../nixpkgs.nix { } }:

let
  styles = pkgs.callPackage ./_support/styles { };
  devices = pkgs.callPackage ./_support/devices { };
in

pkgs.callPackage (

{ runCommandNoCC, cmark-gfm, ruby }:

runCommandNoCC "Tow-Boot-documentation" {
  src = (builtins.fetchGit ../.) + "/doc";
  nativeBuildInputs = [
    cmark-gfm
    (ruby.withPackages (pkgs: with pkgs; [ nokogiri ]))
  ];

  passthru = {
    inherit devices;
  };
} ''
  export LANG="C.UTF-8"
  export LC_ALL="C.UTF-8"

  (PS4=" $ "; set -x
  cp --no-preserve=mode -r $src src
  chmod -R +w src
  cp -r -t src ${devices}/*
  find src/_support -name '*.md' -delete
  ruby ${./_support/converter}/main.rb src/ $out/
  cp -r ${styles} $out/styles
  cp $src/favicon.png $out/
  )
''

) { }
