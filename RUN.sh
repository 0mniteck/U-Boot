#!/bin/bash -e

##
##	Pinephone U-Boot Assembler
##		Requirements: Debian based OS running on ARM64 CPU & any size Unformatted microSD in the MMCBLK1 slot w/ no MBR/GUID
##		  By: Shant Tchatalbachian
##

git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
rm -f build.zip
pushd /tmp/
apt update && apt install build-essential bc zip unzip bison flex libssl-dev device-tree-compiler swig python3-pyelftools python3-dev -y
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/lts-v2.8.8.zip
echo '767cf7af72653432d27043b558fc00550acbfa7e9bbb8c9c7f68c2e15c23ac6af6e28256d7a1912189803371947e824bdb4e5166fb3a7e64097bc838137bc1e0  lts-v2.8.8.zip' > v2.zip.sum
if [[ $(sha512sum -c v2.zip.sum) == 'lts-v2.8.8.zip: OK' ]]; then sleep 0; else exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2023.07.02.zip
echo '3293f165ea9b381d4c1e86a40585a9e5b242da2a37f19b592e23983c9a92ba76a3e4c9b8c56dfd4faa324c4c66bda681cc7510e0ba42202486baa8d0ed4b6182  v2023.07.02.zip' > v2023.zip.sum
if [[ $(sha512sum -c v2023.zip.sum) == 'v2023.07.02.zip: OK' ]]; then sleep 0; else exit 1; fi;
unzip v202*
unzip lts-*
cd arm-trusted-firmware-*
echo "Entering TF-A ------"
make realclean
make PLAT=sun50i_a64 bl31
export BL31=/tmp/arm-trusted-firmware-2.8/build/sun50i_a64/release/bl31/bl31.elf
cd ..
echo "Bypassing Crust ------"
export SCP=/dev/null
cd u-boot-202*
echo "Entering U-Boot ------"
make pinephone_defconfig && make -j$(nproc) all
sha512sum u-boot-sunxi-with-spl.bin
dd if=u-boot-sunxi-with-spl.bin of=/dev/mmcblk1 bs=8k seek=1
sha512sum u-boot-sunxi-with-spl.bin > /tmp/u-boot-sunxi-with-spl.bin.sum
cp u-boot-sunxi-with-spl.bin /tmp/u-boot-sunxi-with-spl.bin
cd ..
zip -0 build.zip u-boot-sunxi-with-spl.bin u-boot-sunxi-with-spl.bin.sum
sync
popd
cp /tmp/build.zip build.zip
git status
git add -A && git status && git commit -a -S -m "Successful Build of U-Boot with TF-A"
git push
apt remove --purge build-essential bc zip unzip bison flex libssl-dev device-tree-compiler swig python3-pyelftools python3-dev -y && apt autoremove -y
rm -f -r /tmp/u-boot-202* && rm -f /tmp/lts-* && rm -f /tmp/v2* && rm -f -r /tmp/arm-trusted-firmware* && rm -f -r /tmp/u-boot* && rm -f /tmp/build*
