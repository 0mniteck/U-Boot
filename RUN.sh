#!/bin/bash -e

##
##	Pinephone U-Boot Assembler
##		Requirements: Debian based OS running on ARM64 CPU & any size Unformatted microSD in the MMCBLK1 slot w/ no MBR/GUID
##		  By: Shant Tchatalbachian
##

pushd /tmp/
apt update && apt install build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi gcc-or1k-elf binutils-or1k-elf device-tree-compiler swig python3-pyelftools python3-dev -y
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/v2.9.zip
echo '07e2500d5a64d4ebce5e5d7a934bdb4e911457402a84a8ca0070e42a65fe424596bb0995d03122867e08d459933f45eb7dd5478a5fcccd03afd16625e0dc2d3d  v2.9.zip' > v2.zip.sum
if [[ $(sha512sum -c v2.zip.sum) == 'v2.9.zip: OK' ]]; then sleep 0; else exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2023.07.02.zip
echo '3293f165ea9b381d4c1e86a40585a9e5b242da2a37f19b592e23983c9a92ba76a3e4c9b8c56dfd4faa324c4c66bda681cc7510e0ba42202486baa8d0ed4b6182  v2023.07.02.zip' > v2023.zip.sum
if [[ $(sha512sum -c v2023.zip.sum) == 'v2023.07.02.zip: OK' ]]; then sleep 0; else exit 1; fi;
wget https://github.com/crust-firmware/crust/archive/refs/tags/v0.6.zip
echo 'e392498b445cc4a8f376cf14d0fa336fc28349bf2bc48db1c3f5afded56f152b843241eb374d5291595efd9e6ce74cf55fcaab0693be4212b1a8b7870ad92e2d  v0.6.zip' > v0.6.zip.sum
if [[ $(sha512sum -c v0.6.zip.sum) == 'v0.6.zip: OK' ]]; then sleep 0; else exit 1; fi;
unzip v202*.zip
unzip v2.*.zip
unzip v0.*.zip
cd arm-trusted-firmware-*
make realclean
make PLAT=sun50i_a64 DEBUG=1 bl31
export BL31=/tmp/arm-trusted-firmware-2.9/build/sun50i_a64/debug/bl31/bl31.elf
cd ..
cd crust-0.*
export CROSS_COMPILE=or1k-elf-
make pinephone_defconfig && make -j$(nproc) scp
export SCP=/tmp/crust-0.6/build/scp/scp.bin
export CROSS_COMPILE=
cd ..
cd u-boot-202*
sed 13d -i configs/pinephone_defconfig
make pinephone_defconfig && make -j$(nproc) all
sha512sum u-boot-sunxi-with-spl.bin
dd if=u-boot-sunxi-with-spl.bin of=/dev/mmcblk1 bs=8k seek=1
sha512sum u-boot-sunxi-with-spl.bin > /tmp/u-boot-sunxi-with-spl.bin.sum
cp u-boot-sunxi-with-spl.bin /tmp/u-boot-sunxi-with-spl.bin
sync
popd
rm -f u-boot-sunxi-with-spl.bin && zip -0 build.zip /tmp/u-boot-sunxi-with-spl.bin /tmp/u-boot-sunxi-with-spl.bin.sum
git status
git add -A && git status && git commit -a -S -m "Successful Build of U-Boot with TF-A & SCP"
git push
apt remove --purge build-essential bc zip unzip bison flex libssl-dev gcc-arm-none-eabi gcc-or1k-elf binutils-or1k-elf device-tree-compiler swig python3-pyelftools python3-dev -y && apt autoremove -y
rm -f -r /tmp/u-boot-202* && rm -f /tmp/lts-* && rm -f /tmp/v2* && rm -f /tmp/v0* && rm -f -r /tmp/crust-0.* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f -r /tmp/u-boot*
