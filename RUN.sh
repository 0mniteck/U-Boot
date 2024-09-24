#!/bin/bash -e

##
##	RockPro64 SPI U-Boot Assembler
##		Requirements: Debian based OS running on an ARM64 CPU & any size microSD in the MMCBLK1 slot
##		  By: Shant Tchatalbachian
##

OPT_VER=4.3.0;
ATF_VER=2.10.4;
UB_VER=2024.07;
FORCE_SOURCE_DATE=1;
SOURCE_DATE_EPOCH="$(date -d "$(date +%D)" +%s)";
SOURCE_DATE="@$SOURCE_DATE_EPOCH";
BUILD_MESSAGE_TIMESTAMP="$(date -u +'%b %d %Y - 00:00:00 +0000')";
export FORCE_SOURCE_DATE;
export SOURCE_DATE;
export SOURCE_DATE_EPOCH;
export BUILD_MESSAGE_TIMESTAMP;
git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
cp includes/0001-rockchip-rk3399-fix-SPI-NOR-flash-not-found-in-U-Boo.patch /tmp/0001-rockchip-rk3399.patch
cp includes/logo.bmp /tmp/logo.bmp
apt update && apt install bc bison build-essential device-tree-compiler dosfstools flex gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-arm-none-eabi libncurses-dev libssl-dev parted python3-dev python3-pyelftools python3-setuptools swig unzip wget zip -y
pushd /tmp/

# echo "CONFIG_LOG=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_LOG_MAX_LEVEL=6" >> rockpro64-rk3399_defconfig
# echo "CONFIG_LOG_CONSOLE=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_LOGLEVEL=6" >> rockpro64-rk3399_defconfig
# echo "CONFIG_ARMV8_SEC_FIRMWARE_SUPPORT=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_FIT_SIGNATURE=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_RSA=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_ECDSA=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_BOOTM_EFI=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_SPI_FLASH_UNLOCK_ALL=n" >> rockpro64-rk3399_defconfig
# echo "CONFIG_TPM2_FTPM_TEE=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_DM_RNG=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_TPM=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_TPM_V1=n" >> rockpro64-rk3399_defconfig
## echo "CONFIG_TPM_V2=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_TPM_RNG=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_TPM2_TIS_SPI=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_TPL_TPM=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_TPM=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_MEASURED_BOOT=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_STACKPROTECTOR=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_TPL_STACKPROTECTOR=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_SPL_STACKPROTECTOR=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_OPTEE_IMAGE=y" >> rockpro64-rk3399_defconfig
echo "CONFIG_TEE=y" >> rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE=y" >> rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TZDRAM_BASE=0x30000000" >> rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TZDRAM_SIZE=0x02000000" >> rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_SERVICE_DISCOVERY=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_OPTEE_IMAGE=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_BOOTM_OPTEE=y" >> rockpro64-rk3399_defconfig
### echo "CONFIG_SCP03=Y" >> rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TA_SCP03=n" >> rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TA_AVB=n" >> rockpro64-rk3399_defconfig
echo "CONFIG_CHIMP_OPTEE=n" >> rockpro64-rk3399_defconfig
# echo "CONFIG_RNG_OPTEE=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_LIB_HW_RAND=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_ARM_FFA_TRANSPORT=y" >> rockpro64-rk3399_defconfig
# echo "CONFIG_FFA_SHARED_MM_BUF_SIZE=4000" >> rockpro64-rk3399_defconfig
# echo "CONFIG_FFA_SHARED_MM_BUF_OFFSET=0" >> rockpro64-rk3399_defconfig
# echo "CONFIG_FFA_SHARED_MM_BUF_ADDR=0x0" >> rockpro64-rk3399_defconfig
#### echo "CONFIG_SUPPORT_EMMC_RPMB=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_SUPPORT_EMMC_BOOT=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_VARIABLE_FILE_STORE=n" >> rockpro64-rk3399_defconfig
# echo "CONFIG_EFI_RNG_PROTOCOL=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_TCG2_PROTOCOL=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_TCG2_PROTOCOL_MEASURE_DTB=y" >> rockpro64-rk3399_defconfig
##### echo "CONFIG_EFI_MM_COMM_TEE=y" >> rockpro64-rk3399_defconfig
#### echo "CONFIG_EFI_VAR_BUF_SIZE=7340032" >> rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_SECURE_BOOT=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_SOFT_SPI=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_MMC_RPMB=y" >> rockpro64-rk3399_defconfig
##### echo "CONFIG_CMD_OPTEE_RPMB=y" >> rockpro64-rk3399_defconfig
### echo "CONFIG_CMD_SCP03=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_TPM=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_TPM_TEST=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_BOOTMENU=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_BOOTEFI_BOOTMGR=y" >> rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_EFIDEBUG=y" >> rockpro64-rk3399_defconfig

wget https://github.com/OP-TEE/optee_os/archive/refs/tags/$(echo $OPT_VER).zip
echo '04a2e85947283e49a79cb8d60fde383df28303a9be15080a7f5354268b01f16405178c0c570e253256c3be8e3084d812c8b46b6dc2cb5c8eb3bde8d2ba4c380e  '$(echo $OPT_VER)'.zip' > $(echo $OPT_VER).zip.sum
if [[ $(sha512sum -c $(echo $OPT_VER).zip.sum) == $(echo $OPT_VER)'.zip: OK' ]]; then echo 'OP-TEE Checksum Matched!'; else echo 'OP-TEE Checksum Mismatched!' & exit 1; fi;
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/lts-v$(echo $ATF_VER).zip
echo '5252dc59f1133d9c3fae5560954d9810e97a7e3b018522fddea584343d742a110c65678115cb0f554c201b5f7326353eec9a54031485156b6ca0788f53d33882  lts-v'$(echo $ATF_VER)'.zip' > v$(echo $ATF_VER).zip.sum
if [[ $(sha512sum -c v$(echo $ATF_VER).zip.sum) == 'lts-v'$(echo $ATF_VER)'.zip: OK' ]]; then echo 'ATF Checksum Matched!'; else echo 'ATF Checksum Mismatched!' & exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v$(echo $UB_VER).zip
echo '0a3e614ba0fd14224f52a8ad3e68e22df08f6e02c43e9183a459d80b4f37b4f384a4bfef7627a3863388fcffb1472c38d178810bed401f63eb8b5d0a21456603  v'$(echo $UB_VER)'.zip' > v$(echo $UB_VER).zip.sum
if [[ $(sha512sum -c v$(echo $UB_VER).zip.sum) == 'v'$(echo $UB_VER)'.zip: OK' ]]; then echo 'U-Boot Checksum Matched!'; else echo 'U-Boot Checksum Mismatched!' & exit 1; fi;
unzip $(echo $OPT_VER).zip
unzip lts-v$(echo $ATF_VER).zip
unzip v$(echo $UB_VER).zip -d /tmp/RP64
unzip v$(echo $UB_VER).zip -d /tmp/PBP

cd optee_os-$(echo $OPT_VER)
echo "Entering OP-TEE ------"
make -j$(nproc) PLATFORM=rockchip-rk3399 CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu-
export TEE=/tmp/optee_os-$(echo $OPT_VER)/out/arm-plat-rockchip/core/tee.bin
cd ..

cd arm-trusted-firmware-lts-v$(echo $ATF_VER)
echo "Entering TF-A ------"
make realclean
make BUILD_MESSAGE_TIMESTAMP="$(echo '"'$BUILD_MESSAGE_TIMESTAMP'"')" PLAT=rk3399 bl31
export BL31=/tmp/arm-trusted-firmware-lts-v$(echo $ATF_VER)/build/rk3399/release/bl31/bl31.elf
cd ..

cd RP64
echo "Entering U-Boot ------"
make clean
git apply ../0001-rockchip-rk3399.patch && echo "Patched SPI bug"
rm tools/logos/denx.bmp && rm drivers/video/u_boot_logo.bmp
cp /tmp/logo.bmp tools/logos/denx.bmp && cp /tmp/logo.bmp drivers/video/u_boot_logo.bmp
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/rockpro64-rk3399_defconfig
cat /tmp/rockpro64-rk3399_defconfig >> configs/rockpro64-rk3399_defconfig
make rockpro64-rk3399_defconfig
FORCE_SOURCE_DATE=1 SOURCE_DATE=$SOURCE_DATE SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH make -j$(nproc) all
sha512sum u-boot-rockchip.bin
sha512sum u-boot-rockchip-spi.bin
read -p "Insert any SD Card, Then Press Enter to Continue"
dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=2000 status=progress
parted /dev/mmcblk1 mktable gpt mkpart P1 fat32 16MB 1G -s && sleep 3
mkfs.fat /dev/mmcblk1p1
mount /dev/mmcblk1p1 /mnt
sha512sum u-boot-rockchip.bin
sha512sum u-boot-rockchip.bin > u-boot-rockchip.bin.sum
sha512sum u-boot-rockchip.bin > /mnt/u-boot-rockchip.bin.sum
cp u-boot-rockchip.bin /mnt/u-boot-rockchip.bin
sha512sum u-boot-rockchip-spi.bin
sha512sum u-boot-rockchip-spi.bin > u-boot-rockchip-spi.bin.sum
sha512sum u-boot-rockchip-spi.bin > /mnt/u-boot-rockchip-spi.bin.sum
cp u-boot-rockchip-spi.bin /mnt/u-boot-rockchip-spi.bin
sync
umount /mnt
dd if=u-boot-rockchip.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
sync
dd if=/dev/mmcblk1 of=sdcard.img bs=1M count=1024 status=progress
sha512sum sdcard.img > sdcard.img.sum
cd ..

cd PBP
echo "Entering U-Boot ------"
make clean
git apply ../0001-rockchip-rk3399.patch && echo "Patched SPI bug"
rm tools/logos/denx.bmp && rm drivers/video/u_boot_logo.bmp
cp /tmp/logo.bmp tools/logos/denx.bmp && cp /tmp/logo.bmp drivers/video/u_boot_logo.bmp
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/pinebook-pro-rk3399_defconfig
cat /tmp/rockpro64-rk3399_defconfig >> configs/pinebook-pro-rk3399_defconfig
make pinebook-pro-rk3399_defconfig
FORCE_SOURCE_DATE=1 SOURCE_DATE=$SOURCE_DATE SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH make -j$(nproc) all
sha512sum u-boot-rockchip.bin
sha512sum u-boot-rockchip-spi.bin
read -p "Insert any SD Card, Then Press Enter to Continue"
dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=2000 status=progress
parted /dev/mmcblk1 mktable gpt mkpart P1 fat32 16MB 1G -s && sleep 3
mkfs.fat /dev/mmcblk1p1
mount /dev/mmcblk1p1 /mnt
sha512sum u-boot-rockchip.bin
sha512sum u-boot-rockchip.bin > u-boot-rockchip.bin.sum
sha512sum u-boot-rockchip.bin > /mnt/u-boot-rockchip.bin.sum
cp u-boot-rockchip.bin /mnt/u-boot-rockchip.bin
sha512sum u-boot-rockchip-spi.bin
sha512sum u-boot-rockchip-spi.bin > u-boot-rockchip-spi.bin.sum
sha512sum u-boot-rockchip-spi.bin > /mnt/u-boot-rockchip-spi.bin.sum
cp u-boot-rockchip-spi.bin /mnt/u-boot-rockchip-spi.bin
sync
umount /mnt
dd if=u-boot-rockchip.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
sync
dd if=/dev/mmcblk1 of=sdcard.img bs=1M count=1024 status=progress
sha512sum sdcard.img > sdcard.img.sum
cd ..
popd

mv /tmp/RP64/sdcard.img Builds/RP64/sdcard.img
mv /tmp/RP64/sdcard.img.sum Builds/RP64/sdcard.img.sum
mv /tmp/RP64/u-boot-rockchip.bin Builds/RP64/u-boot-rockchip.bin
mv /tmp/RP64/u-boot-rockchip.bin.sum Builds/RP64/u-boot-rockchip.bin.sum
mv /tmp/RP64/u-boot-rockchip-spi.bin Builds/RP64/u-boot-rockchip-spi.bin
mv /tmp/RP64/u-boot-rockchip-spi.bin.sum Builds/RP64/u-boot-rockchip-spi.bin.sum

mv /tmp/PBP/sdcard.img Builds/PBP/sdcard.img
mv /tmp/PBP/sdcard.img.sum Builds/PBP/sdcard.img.sum
mv /tmp/PBP/u-boot-rockchip.bin Builds/PBP/u-boot-rockchip.bin
mv /tmp/PBP/u-boot-rockchip.bin.sum Builds/PBP/u-boot-rockchip.bin.sum
mv /tmp/PBP/u-boot-rockchip-spi.bin Builds/PBP/u-boot-rockchip-spi.bin
mv /tmp/PBP/u-boot-rockchip-spi.bin.sum Builds/PBP/u-boot-rockchip-spi.bin.sum

git status && git add -A && git status
read -p "Successful Build of U-Boot v$(echo $UB_VER) at $(echo $BUILD_MESSAGE_TIMESTAMP) W/ TF-A $(echo $ATF_VER) & OP-TEE $(echo $OPT_VER) For rk3399: Sign -->"
git commit -a -S -m "Successful Build of U-Boot v$(echo $UB_VER) at $(echo $BUILD_MESSAGE_TIMESTAMP) W/ TF-A $(echo $ATF_VER) & OP-TEE $(echo $OPT_VER) For rk3399"
git push --set-upstream origin rk3399-A
cd ..
apt remove --purge bc bison build-essential device-tree-compiler dosfstools flex gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-arm-none-eabi libncurses-dev libssl-dev parted python3-dev python3-pyelftools python3-setuptools swig unzip wget zip -y && apt autoremove -y
rm -f /tmp/4.* && rm -f /tmp/lts* && rm -f /tmp/v2* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f -r /tmp/optee_os-* && rm -f -r /tmp/RP64 && rm -f -r /tmp/PBP && rm -f /tmp/000* && rm -f /tmp/logo.bmp && rm -f -r U-Boot && cd ..
exit
