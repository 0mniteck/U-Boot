#!/bin/bash -e

##
##	RockPro64 SPI U-Boot Assembler
##		Requirements: Debian based OS running on an ARM64 CPU & any size microSD in the MMCBLK1 slot
##		  By: Shant Tchatalbachian
##

git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
rm -f spi_combined.zip
pushd /tmp/
apt update && apt install build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi gcc-arm-linux-gnueabihf device-tree-compiler swig python3-pyelftools python3-setuptools python3-dev parted dosfstools libncurses-dev -y
wget https://github.com/OP-TEE/optee_os/archive/refs/tags/4.1.0.zip
echo '68fc9a141abb491ca82928cf128f91ace94b74012281618bcb389b0c2947f495c8d2938cad6ab3028981ba36fb4f0be12eb8ec8011d53291a02566236d707a11  4.1.0.zip' > 4.zip.sum
if [[ $(sha512sum -c 4.zip.sum) == '4.1.0.zip: OK' ]]; then echo 'OP-TEE Checksum Matched!'; else exit 1; fi;
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/lts-v2.10.2.zip
echo '56288e2d6f4d105ae18a0a07cbf7d8dae7cb868e486a992bb7f168115b823bf111f51cdfecfc97b769747374676e9de74e66ba4277889d6292a3617a1f82f656 lts-v2.10.2.zip' > v2.zip.sum
if [[ $(sha512sum -c v2.zip.sum) == 'lts-v2.10.2.zip: OK' ]]; then echo 'ATF Checksum Matched!'; else exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2023.07.02.zip
echo '3293f165ea9b381d4c1e86a40585a9e5b242da2a37f19b592e23983c9a92ba76a3e4c9b8c56dfd4faa324c4c66bda681cc7510e0ba42202486baa8d0ed4b6182  v2023.07.02.zip' > v2024.zip.sum
if [[ $(sha512sum -c v2024.zip.sum) == 'v2023.07.02.zip: OK' ]]; then echo 'U-Boot Checksum Matched!'; else exit 1; fi;
unzip 4.*.*.zip
unzip v202*.zip
unzip lts*.zip
cd optee_os-*
echo "Entering OP-TEE ------"
make -j$(nproc) PLATFORM=rockchip-rk3399 CFG_ARM64_core=y
export TEE=/tmp/optee_os-4.1.0/out/arm-plat-rockchip/core/tee.bin
cd ..
cd arm-trusted-firmware-*
echo "Entering TF-A ------"
make realclean
make PLAT=rk3399 bl31
export BL31=/tmp/arm-trusted-firmware-lts-v2.10.2/build/rk3399/release/bl31/bl31.elf
cd ..
cd u-boot-202*
echo "Entering U-Boot ------"
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/rockpro64-rk3399_defconfig
make rockpro64-rk3399_defconfig
make -j$(nproc) all
image_name="spi_idbloader.img"
combined_name="spi_combined.img"
tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin "${image_name}"
padsize=$((0x60000 - 1))
image_size=$(wc -c < "${image_name}")
dd if=/dev/zero of="${image_name}" conv=notrunc bs=1 count=1 seek=${padsize}
cat ${image_name} u-boot.itb > "${combined_name}"
read -p "Insert any SD Card, Then Press Enter to Continue"
dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=2000 status=progress
parted /dev/mmcblk1 mktable gpt mkpart P1 fat32 16MB 1G -s && sleep 3
mkfs.fat /dev/mmcblk1p1
mount /dev/mmcblk1p1 /mnt
sha512sum spi_combined.img
sha512sum spi_combined.img > /mnt/spi_combined.img.sum
sha512sum spi_combined.img > /tmp/spi_combined.img.sum
cp spi_combined.img /mnt/spi_combined.img
cp spi_combined.img /tmp/spi_combined.img
sha512sum u-boot-rockchip.bin
sha512sum u-boot-rockchip.bin > /mnt/u-boot-rockchip.bin.sum
sha512sum u-boot-rockchip.bin > /tmp/u-boot-rockchip.bin.sum
cp u-boot-rockchip.bin /tmp/u-boot-rockchip.bin
sync
umount /mnt
dd if=u-boot-rockchip.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
cd ..
zip -0 spi_combined.zip spi_combined.img spi_combined.img.sum u-boot-rockchip.bin u-boot-rockchip.bin.sum
sync
popd
cp /tmp/spi_combined.zip spi_combined.zip
git status && git add -A && git status
read -p "Continue -->"
git commit -a -S -m "Successful Build of U-Boot W/ TF-A & OP-TEE For The RockPro64"
git push --set-upstream origin RP64-rk3399-A
cd ..
apt remove --purge build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi gcc-arm-linux-gnueabihf device-tree-compiler swig python3-pyelftools python3-setuptools python3-dev parted dosfstools libncurses-dev -y && apt autoremove -y
rm -f -r /tmp/u-boot* && rm -f /tmp/4.* && rm -f /tmp/lts* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f -r /tmp/optee_os-* && rm -f /tmp/spi_* && rm -f /tmp/rk*
