{ lib, stdenv, fetchFromGitHub
, withPlatform ? 
, withPayload ? null
, withFDT ? null
}:

stdenv.mkDerivation rec {
  pname = "opensbi";
  version = "unstable-2022-04-28";

  src = fetchFromGitHub {
    owner = "riscv-software-src";
    repo = "opensbi";
    rev = "474a9d45551ab8c7df511a6620de2427a732351f";
    sha256 = "0j2in11ps654kl41w2fffbznn8vml8abi1nps3zsxiljj7g9kkli";
  };

  installFlags = [
    "I=$(out)"
  ];

  makeFlags = [
    "PLATFORM=generic"
    "FW_PAYLOAD_PATH=u-boot.bin"
    "FW_FDT_PATH=u-boot.dtb"
  ];

  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    description = "RISC-V Open Source Supervisor Binary Interface";
    homepage = "https://github.com/riscv-software-src/opensbi";
    license = licenses.bsd2;
    maintainers = with maintainers; [ Madouura ];
    platforms = [ "riscv64-linux" ];
  };
}
