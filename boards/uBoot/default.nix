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
    filesToInstall = ["u-boot" "u-boot.dtb"];
    buildInputs = with nixpkgs; [
      SDL2
      perl
    ];
    patches = [
      ./0001-sandbox-Force-window-size.patch
    ];
  };

  # Virtualization targets

  uBoot-qemuArm = armv7l.buildTowBoot {
    defconfig = "qemu_arm_defconfig";
    meta.platforms = ["armv7l-linux"];
    filesToInstall = ["u-boot.bin"];
  };

  uBoot-qemuArm64 = aarch64.buildTowBoot {
    defconfig = "qemu_arm64_defconfig";
    meta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin"];
  };

  uBoot-qemuX86 = i686.buildTowBoot {
    defconfig = "qemu-x86_defconfig";
    meta.platforms = ["i686-linux"];
    filesToInstall = ["u-boot.rom"];
    withPoweroff = false;
  };

  uBoot-qemuX86_64 = x86_64.buildTowBoot {
    defconfig = "qemu-x86_64_defconfig";
    meta.platforms = ["x86_64-linux"];
    filesToInstall = ["u-boot.rom"];

    # Enabling the logo breaks things left and right
    withLogo = false;

    # STB Truetype can't be used on qemu-x86_64 with U-Boot
    #     error: SSE register return with SSE disabled
    withTTF = false;
    withPoweroff = false;
  };

  # EFI payloads

  uBoot-efiX86 = i686.buildTowBoot {
    defconfig = "efi-x86_payload32_defconfig";
    meta.platforms = ["i686-linux"];
    filesToInstall = ["u-boot-payload.efi"];
    withPoweroff = false;
  };

  uBoot-efiX86_64 = x86_64.buildTowBoot {
    defconfig = "efi-x86_payload64_defconfig";
    meta.platforms = ["x86_64-linux"];
    filesToInstall = ["u-boot-payload.efi"];
    withPoweroff = false;
  };
}
