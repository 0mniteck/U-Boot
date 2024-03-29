# U-Boot RockChip rk3399

Prebuilt spi_combined.img & u-boot-rockchip.bin are included together for convenience

## RockPro64 SPI U-Boot Assembler
## U-Boot (Feb 25 2024 - 07:32:28 +0000)
### Prebuilt Release v2023.07.02 W/ ATF lts-v2.10.2 & OP-TEE v4.1.0


## Pinebook Pro SPI U-Boot Assembler 
## U-Boot (Feb 25 2024 - 19:00:15 +0000)
### Prebuilt Release v2023.07.02 W/ ATF lts-v2.10.2 & OP-TEE v4.1.0


Requirements:

* [ ] Debian based OS already running on an ARM64 CPU

* [ ] Any microSD in the /dev/mmcblk1 slot


# Post-Build
## Initial-Flash From Bypassed and Erased SPI (Recommended)
## or Update-Flash From Existing U-Boot


### Erase current SPI, then boot into U-Boot Via SD/eMMC with Combined SD

`Stop Autoboot by hitting any key`

`Insert SD Card`

`Bypass SPI`

`reset`

### Wait untill you see the environment fail to load from SPI

`Reconnect SPI`

`Stop Autoboot by hitting any key`

`sf probe`

`sf erase 0x0 0x1000000`

`reset`

`Stop Autoboot by hitting any key`

`ls mmc 1:1 /`

`load mmc 1:1 $kernel_addr_r spi_combined.img`

`sf probe`

`sf write $kernel_addr_r 0 $filesize`

`reset`

`Stop Autoboot by hitting any key`

`saveenv`

`reset`
