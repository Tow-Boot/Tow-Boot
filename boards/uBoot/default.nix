{ nixpkgs, buildTowBoot, systems }:

let
  inherit (systems)
    aarch64
    armv7l
    i686
    x86_64
  ;
in

{
  # Sandbox

  uBoot-sandbox = buildTowBoot {
    defconfig = "sandbox_defconfig";
    buildInputs = with nixpkgs; [
      SDL2
      perl
    ];
    patches = [
      ./0001-sandbox-Force-window-size.patch
    ];
    internal = true;
    variant = "noenv";

    # TODO: Add helper bin to start with dtb file
    installPhase = ''
      rmdir $out/binaries
      mkdir -p $out/libexec
      cp -v u-boot $out/libexec/tow-boot
      cp -v u-boot.dtb $out/tow-boot.dtb
    '';
  };

  # Virtualization targets

  uBoot-qemuArm = armv7l.buildTowBoot {
    defconfig = "qemu_arm_defconfig";
    meta.platforms = ["armv7l-linux"];
    internal = true;
    variant = "noenv";
    installPhase = ''
      cp -v u-boot.bin $out/binaries/tow-boot.$variant.bin
    '';
  };

  uBoot-qemuArm64 = aarch64.buildTowBoot {
    defconfig = "qemu_arm64_defconfig";
    meta.platforms = ["aarch64-linux"];
    internal = true;
    variant = "noenv";
    installPhase = ''
      cp -v u-boot.bin $out/binaries/tow-boot.$variant.bin
    '';
  };

  uBoot-qemuX86 = i686.buildTowBoot {
    defconfig = "qemu-x86_defconfig";
    meta.platforms = ["i686-linux"];
    withPoweroff = false;
    internal = true;
    variant = "noenv";
    installPhase = ''
      cp -v u-boot.rom $out/binaries/tow-boot.$variant.rom
    '';
  };

  uBoot-qemuX86_64 = x86_64.buildTowBoot {
    defconfig = "qemu-x86_64_defconfig";
    meta.platforms = ["x86_64-linux"];

    # Enabling the logo breaks things left and right
    withLogo = false;

    # STB Truetype can't be used on qemu-x86_64 with U-Boot
    #     error: SSE register return with SSE disabled
    withTTF = false;
    withPoweroff = false;
    internal = true;
    variant = "noenv";
    installPhase = ''
      cp -v u-boot.rom $out/binaries/tow-boot.$variant.rom
    '';
    extraConfig = ''
      CONFIG_SPL_ENV_SUPPORT=y
    '';
  };

  # EFI payloads

  uBoot-efiX86 = i686.buildTowBoot {
    defconfig = "efi-x86_payload32_defconfig";
    meta.platforms = ["i686-linux"];
    withPoweroff = false;
    internal = true;
    variant = "noenv";
    installPhase = ''
      cp -v u-boot-payload.efi $out/binaries/tow-boot.$variant.efi
    '';
  };

  uBoot-efiX86_64 = x86_64.buildTowBoot {
    defconfig = "efi-x86_payload64_defconfig";
    meta.platforms = ["x86_64-linux"];
    withPoweroff = false;
    internal = true;
    variant = "noenv";
    installPhase = ''
      cp -v u-boot-payload.efi $out/binaries/tow-boot.$variant.efi
    '';
  };
}
