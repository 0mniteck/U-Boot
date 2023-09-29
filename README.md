# U-Boot RockChip rk3399
## U-Boot Prebuilt Release v2023.07.02 W/ ATF v2.9

Prebuilt spi_combined.img is included for convenience.

## Pinebook Pro SPI U-Boot Assembler

Requirements:

* [ ] Debian based OS already running on an ARM64 CPU

* [ ] Any size Fat formatted microSD in the /dev/mmcblk1 slot w/ no MBR/GUID


## Post-Build

Reboot into U-Boot, Then:

`sf probe`

`sf erase 0x0 0x1000000`

`ls mmc 1:0 /`

`load mmc 1:0 $kernel_addr_r spi_combined.img`

`sf write $kernel_addr_r 0 $filesize`

`reset`

`saveenv`

`reset`
