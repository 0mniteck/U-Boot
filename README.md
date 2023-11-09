# U-Boot RockChip rk3399
## U-Boot Prebuilt Release v2023.07.02 W/ ATF lts-v2.8.10

Prebuilt spi_combined.img & u-boot-rockchip.bin are included for convenience

# Pinebook Pro SPI U-Boot Assembler

Requirements:

* [ ] Debian based OS already running on an ARM64 CPU

* [ ] Any size Fat formatted microSD in the /dev/mmcblk1 slot w/ no MBR/GUID


# Post-Build
## Initial-Flash From Blank or Bypassed SPI (Recommended)

1. Bypass current SPI, then boot into U-Boot Via SD/eMMC with u-boot-rockchip.bin
2. Swap SD then flash the SPI with spi_combined.img

`dd if=u-boot-rockchip.bin of=/dev/mmcblkX conv=notrunc seek=64`

`Insert SD/eMMC Card with u-boot-rockchip.bin`

`Stop Autoboot by hitting any key`

`Insert SD Card with spi_combined.img`

`mmc rescan`

`sf probe`

`sf erase 0x0 0x1000000`

`ls mmc 1:0 /`

`load mmc 1:0 $kernel_addr_r spi_combined.img`

`sf write $kernel_addr_r 0 $filesize`

`reset`

`saveenv`

`reset`

## Update-Flash From Existing U-Boot

`Insert SD Card with spi_combined.img`

`Stop Autoboot by hitting any key`

`sf probe`

`sf erase 0x0 0x1000000`

`ls mmc 1:0 /`

`load mmc 1:0 $kernel_addr_r spi_combined.img`

`sf write $kernel_addr_r 0 $filesize`

`reset`

`saveenv`

`reset`
