Arch Linux ARM
==============

This guide uses the [*generic AArch64 installation*](https://archlinuxarm.org/platforms/armv8/generic) as a base.

It is assumed that Tow-Boot has already been installed (e.g. to SPI), or that
the storage media was initialized with the *shared storage* disk image. Please
refer to [Getting Started](../getting-started.md).

This installation guide assumes the use of the tarball extracted to a single
non-encrypted root filesystem.

This installation boots using the "extlinux.conf-compatible" boot scheme.

Deviating from the usual setup, this uses only one partition for the system.
The firmware is able to look in an EXT4 partition. Users are free to customize
the setup as they see fit.


Installation steps
------------------

> **NOTE**: This guide uses `/dev/sdX` as a generic placeholder for the target
> storage device, and `/mnt` for the temporary mount point.
>
> Usage of `sudo` commands is used to denote commands requiring root
> privileges.

### 0. Preparations

Download the latest generic tarball.

```
 ~ $ wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
```

### 1. Partitions and filesystems

#### 1.1. Initializing the disk

> **WARNING**: Skip this step and go to (1.2)  if you are using the *shared
> storage strategy*. The disk image will provide you with a usable and
> pre-configured partition table.

```
 ~ $ sudo parted /dev/sdX -- mklabel gpt
```

#### 1.2. Adding partitions

This adds the root partition, filling the drive.

```
 ~ $ sudo parted /dev/sdX -- mkpart primary archlinuxarm-rootfs 0 100%
```

Verify the number of the added partition. This guide assumes this is partition
1, `/dev/sdX1` will be used to refer to this partition.

```
 ~ $ sudo parted /dev/sdX -- print
Model: SD SD16G (sd/mmc)
Disk /dev/sdX: 15.5GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name                 Flags
 1      1049kB  15.5GB  15.5GB  ext4         archlinuxarm-rootfs  legacy_boot

```

Finally, the generic distro boot concept relies on the *legacy boot* flag to
be on to attempt to boot a partition.

```
     # Change `set 1` to refer to the rootfs partition number.
 ~ $ sudo parted /dev/sdX -- set 1 legacy_boot on
```

#### 1.3 Formatting

```
 ~ $ sudo mkfs.ext4 -L ROOT_ALARM /dev/sdX1
mke2fs 1.45.5 (07-Jan-2020)
Discarding device blocks: done                            
Creating filesystem with 3778048 4k blocks and 944704 inodes
Filesystem UUID: 11111111-1111-1111-1111-111111111111
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done   
```

### 2. Installing

From this point on, I'm paraphrasing from the generic install guide.

### 2.1 Mounting

```
 ~ $ sudo mount /dev/sdX1 /mnt
```

### 2.2 Copying files

```
 ~ $ sudo bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /mnt
```

### 3. Making bootable

While there is a valid `rootfs` in the target storage, we're missing *some*
way for the device to know what to boot.

Take care of customizing the kernel command-line arguments as you see fit. This
specific command-like does not enable any serial console.

```
 ~ $ cd /mnt/boot
 ~ $ sudo mkdir extlinux
 /mnt/boot $ sudo tee extlinux/extlinux.conf <<EOF
LABEL Arch Linux ARM
KERNEL /boot/Image
FDTDIR /boot/dtbs/
APPEND initrd=/boot/initramfs-linux.img console=tty0 root=LABEL=ROOT_ALARM rw rootwait
EOF
```

### 4. Winding down

```
 /mnt/boot $ cd
 ~ $ sudo umount /mnt
 ~ $ sudo eject /dev/sdX
```

### 5. Booting

Insert the storage media in your device, and boot it. If it is supported by the
mainline kernel build as produced by Arch Linux ARM, it should boot.


Misc. Notes
-----------

The current instructions are mainly geared towards producing *external*
bootable media. The user might want to follow those instructions from the
booted external media into the internal storage media to install.

Instructions to install using `pacstrap` and a UEFI bootable USB drive, just
like "normal" Arch Linux would be welcome. It would make things easier for
everyone to start considering those ARM platforms that can do standards-based
boots "normal" platforms and simply do the usual installation steps.
