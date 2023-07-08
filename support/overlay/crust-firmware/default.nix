{ stdenv
, lib
, fetchFromGitHub
, flex
, yacc
, or1k-toolchain
}:

{ defconfig }:

stdenv.mkDerivation rec {
  pname = "crust-firmware";
  version = "untagged-2023-02-28";

  src = fetchFromGitHub {
    owner = "crust-firmware";
    repo = "crust";
    rev = "c308a504853e7fdb47169796c9a832796410ece8";
    sha256 = "sha256-AobVD3Jo/6s0cExHXpYYAqZv/gCplxLlDYVscSCIS6M=";
  };

  depsBuildBuild = [
    stdenv.cc
  ];

  nativeBuildInputs = [
    flex
    yacc
  ] ++ (with or1k-toolchain; [
    binutils
    gcc
  ]);

  postPatch = ''
    substituteInPlace Makefile --replace "= lex" '= ${flex}/bin/flex'
  '';

  buildPhase = ''
    export CROSS_COMPILE=or1k-elf-
    export HOST_COMPILE=${stdenv.cc}/bin/${stdenv.cc.bintools.targetPrefix}

    make ${defconfig}
    make scp
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v build/scp/scp.bin $out
  '';

  meta = with lib; {
    description = "Libre SCP firmware for Allwinner sunxi SoCs";
    homepage = "https://github.com/crust-firmware/crust";
    license = with licenses; [ bsd3 gpl2Only mit ];
    maintainers = [ maintainers.noneucat ];
    platforms = platforms.all;
  };
}

