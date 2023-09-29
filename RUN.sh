#!/bin/bash -e

##
##	Pinebook Pro SPI-Uboot Assembler
##		Requirements: Debian based OS already running on an ARM64 CPU, any size unformatted microSD in the MMCBLK1 slot w/ no MBR/GUID
##		  By: Shant Tchatalbachian
##

pushd /tmp/
apt update && apt install build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi device-tree-compiler swig python3-pyelftools python3-dev -y
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/v2.9.zip
echo '07e2500d5a64d4ebce5e5d7a934bdb4e911457402a84a8ca0070e42a65fe424596bb0995d03122867e08d459933f45eb7dd5478a5fcccd03afd16625e0dc2d3d  v2.9.zip' > v2.zip.sum
if [[ $(sha512sum -c v2.zip.sum) == 'v2.9.zip: OK' ]]; then sleep 0; else exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2023.07.02.zip
echo '3293f165ea9b381d4c1e86a40585a9e5b242da2a37f19b592e23983c9a92ba76a3e4c9b8c56dfd4faa324c4c66bda681cc7510e0ba42202486baa8d0ed4b6182  v2023.07.02.zip' > v2023.zip.sum
if [[ $(sha512sum -c v2023.zip.sum) == 'v2023.07.02.zip: OK' ]]; then sleep 0; else exit 1; fi;
unzip v202*.zip
unzip v2.*.zip
cd arm-trusted-firmware-*
make realclean
sed -i '/--fatal-warnings -O1/ s/$/ --no-warn-rwx-segments/' Makefile
make PLAT=rk3399 bl31
export BL31=/tmp/arm-trusted-firmware-2.9/build/rk3399/release/bl31/bl31.elf
cd ..
cd u-boot-202*
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/pinebook-pro-rk3399_defconfig
make pinebook-pro-rk3399_defconfig && make -j$(nproc) all
image_name="spi_idbloader.img"
combined_name="spi_combined.img"
tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin "${image_name}"
padsize=$((0x60000 - 1))
image_size=$(wc -c < "${image_name}")
[ $image_size -le $padsize ] || exit 1
dd if=/dev/zero of="${image_name}" conv=notrunc bs=1 count=1 seek=${padsize}
cat ${image_name} u-boot.itb > "${combined_name}"
mount /dev/mmcblk1 /mnt
sha512sum spi_combined.img
sha512sum spi_combined.img > /mnt/spi_combined.img.sum
sha512sum spi_combined.img > /tmp/spi_combined.img.sum
cp spi_combined.img /mnt/spi_combined.img
cp spi_combined.img /tmp/spi_combined.img
sync
umount /mnt
popd
rm -f -r spi_combined.zip && zip -0 spi_combined.zip /tmp/spi_combined.img /tmp/spi_combined.img.sum
git status
git add -A && git status && git commit -a -S -m "Successful Build of U-Boot with TF-A"
git push
apt remove --purge build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi device-tree-compiler swig python3-pyelftools python3-dev -y && apt autoremove -y
rm -f -r /tmp/u-boot-202* && rm -f /tmp/lts-* && rm -f /tmp/v2* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f -r /tmp/spi_*
