{ lib, stdenv, fetchFromGitHub, openssl }:

stdenv.mkDerivation rec {
  pname = "gxlimg";
  version = "unstable-2020-10-30";

  src = fetchFromGitHub {
    owner = "repk";
    repo = pname;
    rev = "c545568fdd6a0470da4265a3532f5e652646707f";
    hash = "sha256-mF37tHpbpKWSLRdI1igEuV9kiThqraPBZlj29oZL6RQ=";
  };

  buildInputs = [
    openssl
  ];

  installPhase = ''
    mkdir -p "$out/bin"
    mv gxlimg "$out/bin"
  '';

  meta = with lib; {
    homepage = "https://github.com/repk/gxlimg";
    description = "Boot Image creation tool for amlogic s905x (GXL)";
    license = licenses.bsd2;
    maintainers = with maintainers; [ samueldr ];
  };
}
