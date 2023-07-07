{ pkgs ? import ../nixpkgs.nix { } }:

let
  styles = pkgs.callPackage ./_support/styles { };
  devices = pkgs.callPackage ./_support/devices { };
  output = 
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
      cp -r $src/images $out/images
      echo tow-boot.org > $out/CNAME
      )
    ''

    ) { }
  ;

  archive = pkgs.callPackage (
    { runCommand, docs, name }:
      runCommand "${name}.tar.xz" {
        dir = name;
      } ''
        PS4=" $ "
      
        (
        set -x
        cp --no-preserve=mode,owner -r ${docs} $dir
        tar -vcJf $out $dir
        )
      ''
    ) {
    docs = output;
    name = "docs.tar.xz";
  };

in
output // {
  inherit archive;
}
