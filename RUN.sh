#!/bin/bash -e

##
##	RockPro64 SPI U-Boot Assembler
##		Requirements: Debian based OS running on an ARM64 CPU & any size Fat formatted microSD in the MMCBLK1 slot w/ no MBR/GUID
##		  By: Shant Tchatalbachian
##

git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
rm -f spi_combined.zip
pushd /tmp/
apt update && apt install build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi device-tree-compiler swig python3-pyelftools python3-dev -y
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/lts-v2.8.10.zip
echo 'd951aa52d5bd75615a382c54c5122a711a6313da38c7bdcad356f6ec443827ca1134bee79028957118e4de66a25cc98ad848c1ba746c80f65bd3c9983b24999e  lts-v2.8.10.zip' > v2.zip.sum
if [[ $(sha512sum -c v2.zip.sum) == 'lts-v2.8.10.zip: OK' ]]; then sleep 0; else exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2023.07.02.zip
echo '3293f165ea9b381d4c1e86a40585a9e5b242da2a37f19b592e23983c9a92ba76a3e4c9b8c56dfd4faa324c4c66bda681cc7510e0ba42202486baa8d0ed4b6182  v2023.07.02.zip' > v2023.zip.sum
if [[ $(sha512sum -c v2023.zip.sum) == 'v2023.07.02.zip: OK' ]]; then sleep 0; else exit 1; fi;
unzip v202*.zip
unzip lts-v2.*.zip
cd arm-trusted-firmware-*
echo "Entering TF-A ------"
make realclean
make PLAT=rk3399 bl31
export BL31=/tmp/arm-trusted-firmware-lts-v2.8.10/build/rk3399/release/bl31/bl31.elf
cd ..
cd u-boot-202*
echo "Entering U-Boot ------"
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/rockpro64-rk3399_defconfig
make rockpro64-rk3399_defconfig && make -j$(nproc) all
image_name="spi_idbloader.img"
combined_name="spi_combined.img"
tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin "${image_name}"
padsize=$((0x60000 - 1))
image_size=$(wc -c < "${image_name}")
dd if=/dev/zero of="${image_name}" conv=notrunc bs=1 count=1 seek=${padsize}
cat ${image_name} u-boot.itb > "${combined_name}"
read -p "Insert FAT formatted SD Card & Unformatted eMMC, Then Press Enter to Continue"
mount /dev/mmcblk1 /mnt
sha512sum spi_combined.img
sha512sum spi_combined.img > /mnt/spi_combined.img.sum
sha512sum spi_combined.img > /tmp/spi_combined.img.sum
cp spi_combined.img /mnt/spi_combined.img
cp spi_combined.img /tmp/spi_combined.img
sync
umount /mnt
sha512sum u-boot-rockchip.bin
sha512sum u-boot-rockchip.bin > /tmp/u-boot-rockchip.bin.sum
cp u-boot-rockchip.bin /tmp/u-boot-rockchip.bin
cd ..
zip -0 spi_combined.zip spi_combined.img spi_combined.img.sum u-boot-rockchip.bin u-boot-rockchip.bin.sum
sync
popd
cp /tmp/spi_combined.zip spi_combined.zip
git status
git add -A && git status && git commit -a -S -m "Successful Build of U-Boot with TF-A"
git push --set-upstream origin RP64-rk3399-A
apt remove --purge build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi device-tree-compiler swig python3-pyelftools python3-dev -y && apt autoremove -y
rm -f -r /tmp/u-boot-202* && rm -f /tmp/lts-* && rm -f /tmp/v2* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f /tmp/spi_*
