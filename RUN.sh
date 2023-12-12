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
wget https://github.com/OP-TEE/optee_os/archive/refs/tags/4.0.0.zip
echo 'b291396cd12d39ad9e5689130b448d1fd4e7d27e27380cd28dea883f615049fad1054bd0859381cac60b1b7118967d8de72eb1a6c18b14278f12bd7378856482  4.0.0.zip' > 4.zip.sum
if [[ $(sha512sum -c 4.zip.sum) == '4.0.0.zip: OK' ]]; then echo 'OP-TEE Checksum Matched!'; else exit 1; fi;
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/v2.10.zip
echo 'f5188111df54d7f9a2f178e2d57fda765a874d2f7a24710c569abaf30dca7b44e48bf1180df52c690f569929993bbd8e732824a0afaa73377ff963535c2fc2a8  v2.10.zip' > v2.zip.sum
if [[ $(sha512sum -c v2.zip.sum) == 'v2.10.zip: OK' ]]; then echo 'ATF Checksum Matched!'; else exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2023.10.zip
echo '256e83b931005b3d596ec10c0be74daa3ad433e0e0fc851dae2c209e70d910ad3767c9ce5ba95d1feee362bb4365f056b67ccca1a88fc324471681f99bc4f403  v2023.10.zip' > v2023.zip.sum
if [[ $(sha512sum -c v2023.zip.sum) == 'v2023.10.zip: OK' ]]; then echo 'U-Boot Checksum Matched!'; else exit 1; fi;
unzip 4.*.*.zip
unzip v202*.zip
unzip v2.*.zip
cd optee_os-*
echo "Entering OP-TEE ------"
make -j$(nproc) PLATFORM=rockchip-rk3399 CFG_ARM64_core=y
export TEE=/tmp/optee_os-4.0.0/out/arm-plat-rockchip/core/tee.bin
cd ..
cd arm-trusted-firmware-*
echo "Entering TF-A ------"
make realclean
make PLAT=rk3399 bl31
export BL31=/tmp/arm-trusted-firmware-2.10/build/rk3399/release/bl31/bl31.elf
cd ..
cd u-boot-202*
echo "Entering U-Boot ------"
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/rockpro64-rk3399_defconfig
make rockpro64-rk3399_defconfig
make menuconfig
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
parted /dev/mmcblk1 mktable gpt mkpart P1 fat32 16MB 1G -s
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
git push --set-upstream origin RP64-rk3399-B
cd ..
apt remove --purge build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi gcc-arm-linux-gnueabihf device-tree-compiler swig python3-pyelftools python3-setuptools python3-dev parted dosfstools libncurses-dev -y && apt autoremove -y
rm -f -r /tmp/u-boot* && rm -f /tmp/lts-* && rm -f /tmp/v2* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f /tmp/spi_*
