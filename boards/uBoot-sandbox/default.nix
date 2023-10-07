{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "U-Boot";
    name = "Sandbox";
    identifier = "uBoot-sandbox";
    inRelease = false;
    supportLevel = "unsupported";
  };

  hardware = {
    # TODO: support running on other architectures
    soc = "generic-x86_64";
  };

  Tow-Boot = {
    defconfig = "sandbox_defconfig";
    config = [
      (helpers: with helpers; {
        AUTOBOOT_MENUKEY = lib.mkForce (option no);
        AUTOBOOT_USE_MENUKEY = lib.mkForce (option no);
      })
      (helpers: with helpers; {
        VIDEO_SANDBOX_SDL = yes;
        SANDBOX_RAM_SIZE_MB = freeform "512";
      })
      (helpers: with helpers; {
        BOOTSTD = lib.mkForce yes;
      })
    ];
    builder = {
      buildInputs = [
        pkgs.SDL2
        pkgs.perl
      ];
      # TODO: Add helper bin to start with dtb file
      installPhase = ''
        rmdir $out/binaries
        mkdir -p $out/u-boot
        cp -vt $out/u-boot u-boot u-boot.dtb

        mkdir -p $out/bin
        # NOTE: script is meant to run on any OS
        cat <<EOF > $out/bin/tow-boot-sandbox
        #!/usr/bin/env bash
        set -e
        set -u
        PS4=" \$ "

        dir="\''${BASH_SOURCE[0]%/*}"

        set -x

        ARGS=(
          --fdt "\$dir/../u-boot/u-boot.dtb"
        )

        exec "\$dir/../u-boot/u-boot" "\''${ARGS[@]}" "\$@"
        EOF
        chmod +x $out/bin/*
      '';
    };
  };

  build.default = lib.mkForce config.Tow-Boot.outputs.firmware;
}
