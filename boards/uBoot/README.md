U-Boot special targets
======================

Sandbox
-------

The sandbox allows testing the behaviour of many components of the firmware
without involving a real (or virtual) device.

The graphical aspect of the firmware can be tested, as can many of the user
experience details.

See:

  - [U-Boot: doc/arch/sandbox.rst](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/arch/sandbox.rst)

QEMU
----

Those four targets produce ROM images that can be used with QEMU for their
respective native targets.

### ARM

Hint:

```
 $ qemu-system-arm -nographic -machine virt -bios result/u-boot.bin
```

See:

  - [U-Boot: doc/board/emulation/qemu-arm.rst](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/board/emulation/qemu-arm.rst)


### ARM64

Hint:

```
 $ qemu-system-aarch64 -nographic -machine virt -cpu cortex-a57 -bios result/u-boot.bin
```

See:

  - [U-Boot: doc/board/emulation/qemu-arm.rst](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/board/emulation/qemu-arm.rst)


### X86

Hint:

```
 $ qemu-system-i386 -nographic -bios result/u-boot.rom
```

See:

  - [U-Boot: doc/board/emulation/qemu-x86.rst](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/board/emulation/qemu-x86.rst)


### X86_64

Hint:

```
 $ qemu-system-x86_64 -nographic -bios result/u-boot.rom
```

See:

  - [U-Boot: doc/board/emulation/qemu-x86.rst](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/board/emulation/qemu-x86.rst)


EFI Payloads
------------

Hint:

> Using `-drive file=fat` with QEMU seems to not work as expected with a
> read-only store path.

```
 # Please also acquire a 32 bit OVMF build.
 $ env -i nix-build -A efi-x86
 $ mkdir -p tmp/EFI/BOOT
 $ cp result/u-boot-payload.efi tmp/EFI/BOOT/BOOTX64.EFI
 $ chmod +rw -R tmp/
 $ qemu-system-i386 -nographic -bios OVMF/bios32.bin -drive file=fat:rw:tmp
```

```
 $ env -i nix-build -I nixpkgs=channel:nixos-unstable '<nixpkgs>' -A OVMF.fd --out-link ovmf-x86_64
 $ env -i nix-build -A efi-x86_64
 $ mkdir -p tmp/EFI/BOOT
 $ cp result/u-boot-payload.efi tmp/EFI/BOOT/BOOTX64.EFI
 $ chmod +rw -R tmp/
 $ qemu-system-x86_64 -nographic -bios ovmf-x86_64-fd/FV/OVMF.fd -drive file=fat:rw:tmp/
```

See:

 - [U-Boot: doc/develop/uefi/u-boot_on_efi.rst](https://source.denx.de/u-boot/u-boot/-/blob/master/doc/develop/uefi/u-boot_on_efi.rst)
