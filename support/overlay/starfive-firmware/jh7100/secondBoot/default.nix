{ stdenv
, lib
, pkgs
, pkgsCross
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "jh7100-secondBoot";
  version = "2021.11.02";

  src = fetchFromGitHub {
    owner = "starfive-tech";
    repo = "JH7100_secondBoot";
    rev = "0b86f96e757ad86641a7dbbe9df0762357c36ace";
    sha256 = "1szsksxgpri9jvj092hkv1z491bnbn50mb6l7q4nzlls2zrl6mfi";
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
    cp bootloader-JH7100-*.bin.out $out/$pname-$version.bin

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
