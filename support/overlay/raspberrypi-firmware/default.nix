{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  # NOTE: this should be updated with linux_rpi
  pname = "raspberrypi-firmware";
  version = "1.20230106";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "firmware";
    rev = version;
    hash = "sha512-iKUR16RipN8BGAmXteTJUzd/P+m5gnbWCJ28LEzYfOTJnGSal63zI7LDQg/HIKXx9wMTARQKObeKn+7ioS4QkA==";
  };

  installPhase = ''
    mkdir -p $out/share/raspberrypi/boot/overlays/

    # Limit the files stored to only what we need
    cp -v boot/bcm271[01]* $out/share/raspberrypi/boot/
    cp -v boot/bootcode.bin boot/fixup*.dat boot/start*.elf $out/share/raspberrypi/boot/
    cp -v boot/overlays/* $out/share/raspberrypi/boot/overlays/

    # NOTICE: The license should be distributed along with the binaries
    cp -v boot/LICENCE.broadcom $out/share/raspberrypi/boot/
  '';

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  meta = with lib; {
    description = "Firmware for the Raspberry Pi board";
    homepage = "https://github.com/raspberrypi/firmware";
    license = licenses.unfreeRedistributableFirmware; # See https://github.com/raspberrypi/firmware/blob/master/boot/LICENCE.broadcom
    maintainers = with maintainers; [ dezgeg ];
    broken = stdenvNoCC.isDarwin; # Hash mismatch on source, mystery.
  };
}
