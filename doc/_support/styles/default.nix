{ stdenv
, runCommandNoCCLocal
, writeShellScriptBin
, nodePackages
}:

let
  embedSVG = writeShellScriptBin "embed-svg" ''
    in=$1
    out=$2

    mkdir -p $in.tmp

    cp $in/*.svg $in.tmp/
    rm -f $in.tmp/*.src.svg

    echo ":: Optimizing svg files"
    for f in $in.tmp/*.svg; do
      echo "::  - $f"
      ${nodePackages.svgo}/bin/svgo $f &
    done
    # Wait until all `svgo` processes are done
    # According to light testing, it is twice as fast that way.
    wait

    echo ":: Embedding SVG files"
    source ${stdenv}/setup # for substituteInPlace
    ls -la $in
    cp $in/svg.less $out
    for f in $in.tmp/*.svg; do
      echo "::  - $f"
      token=$(basename $f)
      token=''${token^^}
      token=''${token//[^A-Z0-9]/_}
      token=SVG_''${token/%_SVG/}
      substituteInPlace $out --replace "@$token)" "'$(cat $f)')"
      substituteInPlace $out --replace "@$token," "'$(cat $f)',"
    done

    rm -rf $in.tmp
  '';

  stylesAssets = runCommandNoCCLocal "tow-boot-styles-assets" {
    nativeBuildInputs = [
      embedSVG
    ];
    src = ./assets;
  } ''
    echo $src
    mkdir -p ./assets
    cp $src/* ./assets
    chmod -R +w ./assets
    embed-svg ./assets $out
  '';

  styles = stdenv.mkDerivation {
    name = "Tow-Boot-docs-styles";

    src = ./.;

    preferLocalBuild = true;
    enableParallelBuilding = true;

    buildInputs = [
      embedSVG
      nodePackages.less
    ];

    installPhase = ''
      #cp --no-preserve=mode -t $out -R *

      rm -rf assets
      mkdir -v assets
      cp ${stylesAssets} assets/svg.less

      mkdir -p $out

      lessc \
        --math=always \
        --verbose \
        --compress \
        index.less $out/index.css

      mkdir -p $out/fonts
      cp -t $out/fonts common/fonts/*.ttf
    '';
  };
in
  styles
