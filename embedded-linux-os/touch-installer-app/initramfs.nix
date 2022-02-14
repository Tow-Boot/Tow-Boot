{ config, lib, pkgs, ... }:

/*

For now the initramfs for the touch-installer example system is entirely bespoke.

At some point a *busybox init stage-1* module will be added, and this will be
changed to use that module.

*/

let
  inherit (lib)
    mkIf
    mkOption
    optionalString
    types
  ;

  inherit (pkgs)
    runCommandNoCC
    writeScript
    writeScriptBin
    writeText
    writeTextFile
    writeTextDir

    mkExtraUtils

    busybox
    glibc

    mmc-utils
  ;

  inherit (config.Tow-Boot.installer.config)
    deviceName
    targetBlockDevice
    storageMedia
  ;

  writeScriptDir = name: text: writeTextFile {inherit name text; executable = true; destination = "${name}";};

  cfg = config.examples.touch-installer;

  # Alias to `output.extraUtils` for internal usage.
  inherit (cfg.output) extraUtils;

  # XXX: for now we only have A64 devices in the touch installer
  # TODO: move the platform knowledge here back into Tow-Boot proper
  anyAllwinner = config.hardware.cpu == "allwinner-a64";
in
{

  options.examples.touch-installer = {
    extraUtils = {
      packages = mkOption {
        # TODO: submodule instead of `attrs` when we extract this
        type = with types; listOf (oneOf [package attrs]);
      };
    };
    output = {
      extraUtils = mkOption {
        type = types.package;
        internal = true;
      };
    };
  };

  config = {
    wip.stage-1.contents = {
      "/etc/issue" = writeTextDir "/etc/issue" ''

        Touch installer system
        ======================

      '';

      # https://git.busybox.net/busybox/tree/examples/inittab
      "/etc/inittab" = writeTextDir "/etc/inittab" ''
        # Allow root login on the `console=` param.
        # (Or when missing, a default console may be launched on e.g. serial)
        # No console will be available on other valid consoles.
        console::respawn:${extraUtils}/bin/getty -l ${extraUtils}/bin/login 0 console

        # Launch all setup tasks
        ::sysinit:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/mount-basic-mounts
        ::sysinit:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/network-setup
        ::sysinit:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/logging-setup
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/start-udev-daemon
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/backlight-setup
        ::respawn:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/start-installer-gui

        ::restart:/bin/init
        ::ctrlaltdel:/bin/poweroff
      '';

      "/etc/passwd" = writeTextDir "/etc/passwd" ''
        root::0:0:root:/root:${extraUtils}/bin/sh
      '';

      "/etc/profile" = writeScriptDir "/etc/profile" ''
        export LD_LIBRARY_PATH="${extraUtils}/lib"
        export PATH="${extraUtils}/bin"
      '';

      # Place init under /etc/ to make / prettier
      init = writeScriptDir "/init" ''
        #!${extraUtils}/bin/sh

        echo
        echo "::"
        echo ":: Launching busybox linuxrc"
        echo "::"
        echo

        . /etc/profile

        exec linuxrc
      '';

      "/etc/udev/rules.d" =
      let
        inherit (pkgs)
          udev
        ;
        inherit (lib)
          getBin
        ;
      in
      runCommandNoCC "udev-rules" {
        allowedReferences = [ extraUtils ];
        preferLocalBuild = true;
      } ''
        mkdir -p $out/etc/udev/rules.d/
   
        cp -vt $out/etc/udev/rules.d/ \
          ${udev}/lib/udev/rules.d/60-cdrom_id.rules \
          ${udev}/lib/udev/rules.d/60-input-id.rules \
          ${udev}/lib/udev/rules.d/60-persistent-input.rules \
          ${udev}/lib/udev/rules.d/60-persistent-storage.rules \
          ${udev}/lib/udev/rules.d/70-touchpad.rules \
          ${udev}/lib/udev/rules.d/80-drivers.rules \
          ${pkgs.lvm2}/lib/udev/rules.d/*.rules \
   
        for i in $out/etc/udev/rules.d/*.rules; do
            substituteInPlace $i \
              --replace ata_id ${extraUtils}/bin/ata_id \
              --replace scsi_id ${extraUtils}/bin/scsi_id \
              --replace cdrom_id ${extraUtils}/bin/cdrom_id \
              --replace ${pkgs.coreutils}/bin/basename ${extraUtils}/bin/basename \
              --replace ${pkgs.utillinux}/bin/blkid ${extraUtils}/bin/blkid \
              --replace ${getBin pkgs.lvm2}/bin ${extraUtils}/bin \
              --replace ${pkgs.mdadm}/sbin ${extraUtils}/sbin \
              --replace ${pkgs.bash}/bin/sh ${extraUtils}/bin/sh \
              --replace ${udev}/bin/udevadm ${extraUtils}/bin/udevadm
        done
   
        # Work around a bug in QEMU, which doesn't implement the "READ
        # DISC INFORMATION" SCSI command:
        #   https://bugzilla.redhat.com/show_bug.cgi?id=609049
        # As a result, `cdrom_id' doesn't print
        # ID_CDROM_MEDIA_TRACK_COUNT_DATA, which in turn prevents the
        # /dev/disk/by-label symlinks from being created.  We need these
        # in the NixOS installation CD, so use ID_CDROM_MEDIA in the
        # corresponding udev rules for now.  This was the behaviour in
        # udev <= 154.  See also
        #   http://www.spinics.net/lists/hotplug/msg03935.html
        substituteInPlace $out/etc/udev/rules.d/60-persistent-storage.rules \
          --replace ID_CDROM_MEDIA_TRACK_COUNT_DATA ID_CDROM_MEDIA
      '';

      extraUtils = runCommandNoCC "touch-installer--initramfs-extraUtils" {
        passthru = {
          inherit extraUtils;
        };
      } ''
        mkdir -p $out/${builtins.storeDir}
        cp -prv ${extraUtils} $out/${builtins.storeDir}
      '';

      # POSIX requires /bin/sh
      "/bin/sh" = runCommandNoCC "touch-installer--initramfs-extraUtils-bin-sh" {} ''
        mkdir -p $out/bin
        ln -s ${extraUtils}/bin/sh $out/bin/sh
      '';
    };

    examples.touch-installer.extraUtils.packages = [
      (mkIf (config.Tow-Boot.installer.config.storageMedia == "EMMCBOOT") {
        package = mmc-utils;
      })
      {
        package = busybox;
        extraCommand = ''
          (cd $out/bin/; ln -s busybox linuxrc)
        '';
      }

      {
        package = runCommandNoCC "empty" {} "mkdir -p $out";
        extraCommand =
        let
          inherit (pkgs) udev;
        in
          ''
            # Copy udev.
            copy_bin_and_libs ${udev}/bin/udevadm
            for BIN in ${udev}/lib/udev/*_id; do
              copy_bin_and_libs $BIN
            done
            ln -sf udevadm $out/bin/systemd-udevd
          ''
        ;
      }

      (writeScriptBin "tow-boot-installer--common-checks" ''

        device="${targetBlockDevice}"

        ${optionalString (config.Tow-Boot.installer.config.storageMedia == "EMMCBOOT") ''
          for f in /sys/block/mmcblk*boot*/force_ro; do
            echo 0 > "$f"
          done
        ''}

        if ! test -e "$device"; then
          echo "Error: $device not found"
          echo ""

          ${optionalString (config.Tow-Boot.installer.config.storageMedia == "SPI") ''
            echo " $ dmesg | grep -i spi"

            echo "---"
            # Also skip GICv3 messages that are irrelevant here...
            dmesg | grep -i spi | grep -v 'GICv3'
            echo "---"
          ''}
          ${optionalString (config.Tow-Boot.installer.config.storageMedia == "EMMCBOOT") ''
            echo " $ dmesg | grep -i mmc"

            echo "---"
            dmesg | grep -i mmc
            echo "---"
          ''}

          exit 4
        fi

      '')

      (writeScriptBin "tow-boot-installer--erase-checks" ''
        #!/bin/sh

        device="${targetBlockDevice}"

        ${optionalString (
          config.Tow-Boot.installer.config.storageMedia == "EMMCBOOT"
          && anyAllwinner
        ) ''
        mmc bootbus set single_hs x1 x4 "$device"
        # Disable boot partition
        mmc bootpart enable 0 0 "$device"
        ''}

        exec tow-boot-installer--common-checks "$@"
      '')

      (writeScriptBin "tow-boot-installer--install-checks" ''
        #!/bin/sh

        device="${targetBlockDevice}"

        ${optionalString (
          config.Tow-Boot.installer.config.storageMedia == "EMMCBOOT"
          && anyAllwinner
        ) ''
        mmc bootbus set single_hs x1 x4 "$device"
        # Enable boot partition 1, enable BOOT_ACK bits
        mmc bootpart enable 1 1 "$device"
        ''}

        exec tow-boot-installer--common-checks "$@"
      '')

      (writeScriptBin "mount-basic-mounts" ''
        #!/bin/sh

        PS4=" $ "
        set -x
        mkdir -p /proc /sys /dev /run /tmp
        mount -t proc proc /proc
        mount -t sysfs sys /sys
        mount -t devtmpfs devtmpfs /dev
        mount -t tmpfs tmpfs /run
      '')

      (writeScriptBin "start-udev-daemon" ''
        #!/bin/sh

        PS4=" $ "
        set -x

        systemd-udevd --daemon

        sleep 1

        udevadm trigger
      '')

      (writeScriptBin "network-setup" ''
        #!/bin/sh

        PS4=" $ "
        set -x
        hostname Tow-Boot
        ip link set lo up
      '')

      (writeScriptBin "logging-setup" ''
        #!/bin/sh

        if [ -e /proc/sys/kernel/printk ]; then
          (
            PS4=" $ "
            set -x
            echo 5 > /proc/sys/kernel/printk
          )
        fi
      '')

      (writeScriptBin "backlight-setup" ''
        #!/bin/sh
        cd /sys/class/backlight/
        for d in *; do
          ( cd $d; echo $(( $(cat max_brightness ) * 30 / 100  )) > brightness )
        done
      '')

      (writeScriptBin "start-installer-gui" ''
        #!/bin/sh

        set -e
        PS4=" $ "
        set -x

        move_to_line() {
          printf '\e[%d;0H' "$@" > /dev/tty0
        }

        pr_info() {
          clear
          printf '\e[2K\r%s' "$@" > /dev/tty0
        }

        move_to_line 999

        pr_info "... waiting for input devices"

        until test -e /dev/input/by-path/; do
          sleep 1
        done

        pr_info "... Launching installer GUI"

        tow-boot-installer-gui

        sleep 10

        clear
      '')
    ];

    examples.touch-installer.output = {
      extraUtils = mkExtraUtils {
        name = "tow-boot-touch-installer--extra-utils";
        inherit (cfg.extraUtils) packages;
      };
    };
  };

}
