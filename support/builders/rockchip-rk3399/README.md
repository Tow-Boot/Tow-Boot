Rockchip RK3399
===============

Notes
-----

### `SYS_SPI_U_BOOT_OFFS`

We are hardcoding `0x80000` / 512KiB as the offset.

Watch out for `u-boot,spl-payload-offset` setting it to another value in your
board's device tree!
