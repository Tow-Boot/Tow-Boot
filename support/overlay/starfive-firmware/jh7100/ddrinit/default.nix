{ stdenv
, lib
, pkgs
, pkgsCross
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "jh7100-ddrinit";
  version = "2021.11.02";

  src = fetchFromGitHub {
    owner = "starfive-tech";
    repo = "JH7100_ddrinit";
    rev = "d086aeeefc4bf7af414ee9219668e0f6faedb7a9";
    sha256 = "1q1p94l6sh7n0m60sxk6lv9yxif7d2skdzx9zrpmm26c62x5cw4k";
  };

  patches = [ ./0001-remove-specs.patch ];
  depsBuildBuild = [ pkgsCross.riscv64-embedded.stdenv.cc ];
  buildInputs = [ pkgs.xxd ];
  makeFlags = [ "CROSSCOMPILE=${pkgsCross.riscv64-embedded.stdenv.cc.targetPrefix}" ];

  postPatch = ''
    patchShebangs build/fsz.sh
  '';

  preBuild = ''
    cd build
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp ddrinit-*.bin.out $out/$pname-$version.bin

    runHook postInstall
  '';

  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    description = "First-stage bootloader for JH7100 RISC-V platforms";
    homepage = "https://github.com/starfive-tech/JH7100_secondBoot";
    license = with licenses; [ gpl2Plus ];
    maintainers = with maintainers; [ Madouura ];
    platforms = platforms.all;
  };
}
