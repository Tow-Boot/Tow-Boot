{ stdenv
, lib
, fetchFromGitHub
, patchelf
}:

stdenv.mkDerivation {
  pname = "rkbin";
  version = "2021-09-21";

  src = fetchFromGitHub {
    rev = "19c4fab37a310765110608b9bd470ce3bedbbfa3";
    owner = "armbian";
    repo = "rkbin";
    sha256 = "0zwg5l3glhrmz6arczkgc8ib6igag7bcb27pkki9xss1ps4b001j";
  };

  nativeBuildInputs = [
    patchelf
  ];

  installPhase = ''
    tools=(
      loaderimage
      trust_merger
    )

    mkdir -p "$out/bin"
    for tool in "''${tools[@]}"; do
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${lib.makeLibraryPath [ stdenv.cc.cc ]}" \
        "tools/$tool"
      mv -v "tools/$tool" "$out/bin"
    done

    mkdir -p $out/share/rkbin
    mv -v -t $out/share/rkbin/ rk* rv*
  '';

  dontBuild = true;

  fixupPhase = ''
  '';

  meta = with lib; {
    license = licenses.unfree;
  };
}
