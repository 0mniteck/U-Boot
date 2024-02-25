# U-Boot RockChip rk3399
## U-Boot Prebuilt Release v2024.01 W/ ATF lts-v2.10.2 & OP-TEE v4.1.0

Prebuilt spi_combined.img & u-boot-rockchip.bin are included together for convenience

# Pinebook Pro SPI U-Boot Assembler

Requirements:

* [ ] Debian based OS already running on an ARM64 CPU

* [ ] Any microSD in the /dev/mmcblk1 slot


# Post-Build
## Initial-Flash From Erased or Bypassed SPI (Recommended)
## or Update-Flash From Existing U-Boot

### Erase current SPI, then boot into U-Boot Via SD/eMMC with Combined SD

`Stop Autoboot by hitting any key`

`sf probe`

`sf erase 0x0 0x1000000`

`Insert SD Card`

`reset`

`Stop Autoboot by hitting any key`

`ls mmc 1:1 /`

`load mmc 1:1 $kernel_addr_r spi_combined.img`

`sf write $kernel_addr_r 0 $filesize`

`reset`

`Stop Autoboot by hitting any key`

`saveenv`

`reset`
