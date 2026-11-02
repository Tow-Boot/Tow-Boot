#!/usr/bin/env python3
"""Verify that the packaged payload contains the actual R8Q Tow-Boot port."""

import pathlib
import re
import sys


def check_port(binary_path, config_path):
    binary = binary_path.read_bytes()
    config = config_path.read_text().splitlines()
    required = [
        "TOW_BOOT_MENU",
        "PDCURSES",
        "BOOTSTD",
        "BOOTSTD_FULL",
        "BOOTMETH_EXTLINUX",
        "BOOTMETH_EFILOADER",
        "CMD_BOOTFLOW",
        "CMD_BOOTFLOW_FULL",
        "BUTTON_KEYBOARD",
        "BUTTON_REMAP_PHONE_KEYS",
        "USB_FUNCTION_ACM",
        "CMD_USB_MASS_STORAGE",
        "ENV_IS_NOWHERE",
        "OF_SEPARATE",
    ]
    for symbol in required:
        if f"CONFIG_{symbol}=y" not in config:
            raise ValueError(f"missing CONFIG_{symbol}=y")
    for symbol in ["EFI_CAPSULE_ON_DISK", "EFI_RUNTIME_UPDATE_CAPSULE"]:
        if f"CONFIG_{symbol}=y" in config:
            raise ValueError(f"unsafe automatic firmware update option: {symbol}")
    if 'CONFIG_DEFAULT_DEVICE_TREE="qcom/sm8250-samsung-r8q"' not in config:
        raise ValueError("firmware targets a different device tree")
    if b"Tow-Boot 2026.10" not in binary:
        raise ValueError("firmware does not identify as Tow-Boot")
    if b"Tow-Boot curses-based menu interface." not in binary:
        raise ValueError("Tow-Boot menu command is not linked")

    text = pathlib.Path(__file__).with_name("tow-boot.env").read_text()
    text = re.sub(r"\\\n[ \t]*", "", text)
    entries = [line for line in text.splitlines() if line and not line.startswith("#")]
    for entry in entries:
        if entry.encode() + b"\0" not in binary:
            raise ValueError(f"missing or truncated environment entry: {entry.split('=')[0]}")
    print(f"R8Q Tow-Boot payload verified ({len(entries)} environment entries)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <u-boot.bin> <build.config>")
    try:
        check_port(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]))
    except (OSError, ValueError) as error:
        sys.exit(f"ERROR: {error}")
