#!/bin/bash -e

##
##	RockPro64 SPI U-Boot Assembler
##		Requirements: Debian based OS running on an ARM64 CPU & any size microSD in the MMCBLK1 slot
##		  By: Shant Tchatalbachian
##

OPT_VER=4.3.0;
ATF_VER=2.10.4;
UB_VER=2024.07;
padsize=$((0x60000 - 1));
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
#cp includes/platform_common.c /tmp/platform_common.c
#cp includes/platform_def.h /tmp/platform_def.h
#cp includes/plat_private.h /tmp/plat_private.h
#cp includes/platform.mk /tmp/platform.mk
#cp includes/rk3399_def.h /tmp/rk3399_def.h
#cp includes/bl31_param.h /tmp/bl31_param.h
cp includes/logo.bmp /tmp/logo.bmp
cp includes/efi.var /tmp/efi.var
apt update && apt install bc bison build-essential device-tree-compiler dosfstools flex gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-arm-none-eabi libncurses-dev libssl-dev parted python3-dev python3-pyelftools python3-setuptools swig unzip wget zip -y
if [ -f Builds/tee.bin ]; then
  cp Builds/tee.bin /tmp/tee.bin
  export TEE=/tmp/tee.bin
  pushd /tmp/
else
  pushd /tmp/
  wget https://github.com/OP-TEE/optee_os/archive/refs/tags/$(echo $OPT_VER).zip
  echo '04a2e85947283e49a79cb8d60fde383df28303a9be15080a7f5354268b01f16405178c0c570e253256c3be8e3084d812c8b46b6dc2cb5c8eb3bde8d2ba4c380e  '$(echo $OPT_VER)'.zip' > $(echo $OPT_VER).zip.sum
  if [[ $(sha512sum -c $(echo $OPT_VER).zip.sum) == $(echo $OPT_VER)'.zip: OK' ]]; then echo 'OP-TEE Checksum Matched!'; else echo 'OP-TEE Checksum Mismatched!' & exit 1; fi;
  unzip $(echo $OPT_VER).zip
  cd optee_os-$(echo $OPT_VER)
  echo "Entering OP-TEE ------"
  make -j$(nproc) PLATFORM=rockchip-rk3399 CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu-
  export TEE=/tmp/optee_os-$(echo $OPT_VER)/out/arm-plat-rockchip/core/tee.bin
  cd ..
  ln -s /tmp/optee_os-$(echo $OPT_VER)/out/arm-plat-rockchip/core/tee.bin
fi
wget https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/lts-v$(echo $ATF_VER).zip
echo '5252dc59f1133d9c3fae5560954d9810e97a7e3b018522fddea584343d742a110c65678115cb0f554c201b5f7326353eec9a54031485156b6ca0788f53d33882  lts-v'$(echo $ATF_VER)'.zip' > v$(echo $ATF_VER).zip.sum
if [[ $(sha512sum -c v$(echo $ATF_VER).zip.sum) == 'lts-v'$(echo $ATF_VER)'.zip: OK' ]]; then echo 'ATF Checksum Matched!'; else echo 'ATF Checksum Mismatched!' & exit 1; fi;
wget https://github.com/u-boot/u-boot/archive/refs/tags/v$(echo $UB_VER).zip
echo '0a3e614ba0fd14224f52a8ad3e68e22df08f6e02c43e9183a459d80b4f37b4f384a4bfef7627a3863388fcffb1472c38d178810bed401f63eb8b5d0a21456603  v'$(echo $UB_VER)'.zip' > v$(echo $UB_VER).zip.sum
if [[ $(sha512sum -c v$(echo $UB_VER).zip.sum) == 'v'$(echo $UB_VER)'.zip: OK' ]]; then echo 'U-Boot Checksum Matched!'; else echo 'U-Boot Checksum Mismatched!' & exit 1; fi;
unzip lts-v$(echo $ATF_VER).zip
unzip v$(echo $UB_VER).zip
cd arm-trusted-firmware-lts-v$(echo $ATF_VER)
echo "Entering TF-A ------"
make realclean
#cp /tmp/platform_common.c plat/rockchip/common/aarch64/platform_common.c
#cp /tmp/platform_def.h plat/rockchip/rk3399/include/platform_def.h
#cp /tmp/plat_private.h plat/rockchip/common/include/plat_private.h
#cp /tmp/platform.mk plat/rockchip/rk3399/platform.mk
#cp /tmp/rk3399_def.h plat/rockchip/rk3399/rk3399_def.h
#cp /tmp/bl31_param.h plat/rockchip/rk3399/include/shared/bl31_param.h
make BUILD_MESSAGE_TIMESTAMP="$(echo '"'$BUILD_MESSAGE_TIMESTAMP'"')" PLAT=rk3399 bl31
export BL31=/tmp/arm-trusted-firmware-lts-v$(echo $ATF_VER)/build/rk3399/release/bl31/bl31.elf
cd ..
cd u-boot-$(echo $UB_VER)
echo "Entering U-Boot ------"
make clean
git apply ../0001-rockchip-rk3399.patch && echo "Patched SPI bug"
cp /tmp/efi.var efi.var
rm tools/logos/denx.bmp && rm drivers/video/u_boot_logo.bmp
cp /tmp/logo.bmp tools/logos/denx.bmp && cp /tmp/logo.bmp drivers/video/u_boot_logo.bmp
sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/rockpro64-rk3399_defconfig
# echo "CONFIG_LOG=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_LOG_MAX_LEVEL=6" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_LOG_CONSOLE=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_LOGLEVEL=6" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_ARMV8_SEC_FIRMWARE_SUPPORT=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_ARM64=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_FIT=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_FIT_VERBOSE=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_FIT=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_LOAD_FIT=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_FIT_SIGNATURE=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_FIT_SIGNATURE=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_RSA=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_ECDSA=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_SPI_FLASH_UNLOCK_ALL=n" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_TPM2_FTPM_TEE=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_DM_RNG=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_TPM=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_TPM_V1=n" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_TPM_V2=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_TPM_RNG=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_TPM2_TIS_SPI=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_TPL_TPM=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_TPM=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_SOFT_SPI=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_MEASURED_BOOT=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_STACKPROTECTOR=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_TPL_STACKPROTECTOR=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_SPL_STACKPROTECTOR=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_SPL_OPTEE_IMAGE=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_TEE=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_OPTEE_TZDRAM_BASE=0x30000000" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TZDRAM_SIZE=0x02000000" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_SERVICE_DISCOVERY=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_OPTEE_IMAGE=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_BOOTM_EFI=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_BOOTM_OPTEE=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TA_SCP03=n" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_OPTEE_TA_AVB=n" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_CHIMP_OPTEE=n" >> configs/rockpro64-rk3399_defconfig
### echo "CONFIG_SCP03=Y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_RNG_OPTEE=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_LIB_HW_RAND=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_ARM_FFA_TRANSPORT=y" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_FFA_SHARED_MM_BUF_SIZE=4000" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_FFA_SHARED_MM_BUF_OFFSET=0" >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_FFA_SHARED_MM_BUF_ADDR=0x0" >> configs/rockpro64-rk3399_defconfig
#### echo "CONFIG_SUPPORT_EMMC_RPMB=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_SUPPORT_EMMC_BOOT=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_VARIABLE_FILE_STORE=n" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_EFI_VARIABLE_NO_STORE=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_EFI_VARIABLES_PRESEED=y" >> configs/rockpro64-rk3399_defconfig
echo 'CONFIG_EFI_VAR_SEED_FILE="efi.var"' >> configs/rockpro64-rk3399_defconfig
# echo "CONFIG_EFI_RNG_PROTOCOL=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_TCG2_PROTOCOL=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_EFI_TCG2_PROTOCOL_MEASURE_DTB=y" >> configs/rockpro64-rk3399_defconfig
##### echo "CONFIG_EFI_MM_COMM_TEE=y" >> configs/rockpro64-rk3399_defconfig
#### echo "CONFIG_EFI_VAR_BUF_SIZE=7340032" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_EFI_SECURE_BOOT=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_EFI_LOADER=y" >> configs/rockpro64-rk3399_defconfig
echo "CONFIG_CMD_BOOTEFI=y" >> configs/rockpro64-rk3399_defconfig
#echo "CONFIG_HEXDUMP=y" >> configs/rockpro64-rk3399_defconfig
#echo "CONFIG_CMD_NVEDIT_EFI=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_MMC_RPMB=y" >> configs/rockpro64-rk3399_defconfig
##### echo "CONFIG_CMD_OPTEE_RPMB=y" >> configs/rockpro64-rk3399_defconfig
### echo "CONFIG_CMD_SCP03=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_TPM=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_TPM_TEST=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_BOOTMENU=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_BOOTEFI_BOOTMGR=y" >> configs/rockpro64-rk3399_defconfig
## echo "CONFIG_CMD_EFIDEBUG=y" >> configs/rockpro64-rk3399_defconfig
make rockpro64-rk3399_defconfig
cat configs/rockpro64-rk3399_defconfig
read -p "menuconfig -->"
make menuconfig
read -p "Build U-Boot -->"
FORCE_SOURCE_DATE=1 SOURCE_DATE=$SOURCE_DATE SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH make -j$(nproc) all
dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=100 status=progress
dd if=u-boot-rockchip.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
read -p "Insert another SD Card, Then Press Enter to Continue"
# wip
mkdir keys
PKCS11_MODULE_PATH=/lib/aarch64-linux-gnu/libykcs11.so.2.2.0 openssl genpkey -algorithm RSA -out keys/dev.key -pkeyopt rsa_keygen_bits:2048 -pkeyopt rsa_keygen_pubexp:65537
PKCS11_MODULE_PATH=/lib/aarch64-linux-gnu/libykcs11.so.2.2.0 openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt
PKCS11_MODULE_PATH=/lib/aarch64-linux-gnu/libykcs11.so.2.2.0 openssl rsa -in keys/dev.key -pubout
tools/mkimage -n rk3399 -T rksd -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin sd_idbloader.img
tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin spi_idbloader.img
PKCS11_MODULE_PATH=/lib/aarch64-linux-gnu/libykcs11.so.2.2.0 tools/mkimage -F -N "" -K simple-bin.fit.fit -r rk3399.fit
tools/mkimage -n rk3399 -T rksd -f auto -d rk3399.fit -A arm64 -O u-boot rk3399.sd.itb
tools/mkimage -n rk3399 -T rkspi -f auto -d rk3399.fit -A arm64 -O u-boot rk3399.spi.itb
dd if=/dev/zero of=sd_idbloader.img conv=notrunc bs=1 count=1 seek=${padsize}
dd if=/dev/zero of=spi_idbloader.img conv=notrunc bs=1 count=1 seek=${padsize}
cat spi_idbloader.img rk3399.sd.itb > rk3399-sd.bin
cat sd_idbloader.img rk3399.spi.itb > rk3399-spi.bin
sha512sum rk3399-sd.bin
sha512sum rk3399-spi.bin
dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=100 status=progress
parted /dev/mmcblk1 mktable gpt mkpart P1 fat32 10MB 25MB -s && sleep 3
mkfs.fat /dev/mmcblk1p1
mount /dev/mmcblk1p1 /mnt
sha512sum rk3399-sd.bin
sha512sum rk3399-sd.bin > /mnt/rk3399-sd.bin.sum
sha512sum rk3399-sd.bin > /tmp/rk3399-sd.bin.sum
cp rk3399-sd.bin /mnt/rk3399-sd.bin
cp rk3399-sd.bin /tmp/rk3399-sd.bin
sha512sum rk3399-spi.bin
sha512sum rk3399-spi.bin > /mnt/rk3399-spi.bin.sum
sha512sum rk3399-spi.bin > /tmp/rk3399-spi.bin.sum
cp rk3399-spi.bin /mnt/rk3399-spi.bin.bin
cp rk3399-spi.bin /tmp/rk3399-spi.bin.bin
sync
umount /mnt
dd if=rk3399-sd.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
cd ..
sync
popd
cp /tmp/rk3399-sd.bin Builds/rk3399-sd.bin
cp /tmp/rk3399-sd.bin.sum Builds/rk3399-sd.bin.sum
cp /tmp/rk3399-spi.bin Builds/rk3399-spi.bin
cp /tmp/rk3399-spi.bin.sum Builds/rk3399-spi.bin.sum
if [[ -f /tmp/optee_os-$(echo $OPT_VER)/out/arm-plat-rockchip/core/tee.bin ]]; then
  cp /tmp/optee_os-$(echo $OPT_VER)/out/arm-plat-rockchip/core/tee.bin Builds/tee.bin;
else
  echo "TEE Build Skipped";
fi
git status && git add -A && git status
read -p "Successful Build of U-Boot v$(echo $UB_VER) at $(echo $BUILD_MESSAGE_TIMESTAMP) W/ TF-A $(echo $ATF_VER) & OP-TEE $(echo $OPT_VER) For The RockPro64: Sign -->"
git commit -a -S -m "Successful Build of U-Boot v$(echo $UB_VER) at $(echo $BUILD_MESSAGE_TIMESTAMP) W/ TF-A $(echo $ATF_VER) & OP-TEE $(echo $OPT_VER) For The RockPro64"
git push --set-upstream origin RP64-rk3399-Dev
cd ..
apt remove --purge bc bison build-essential device-tree-compiler dosfstools flex gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-arm-none-eabi libncurses-dev libssl-dev parted python3-dev python3-pyelftools python3-setuptools swig unzip wget zip -y && apt autoremove -y
rm -f -r /tmp/u-boot* && rm -f /tmp/rk3399* && rm -f /tmp/4.* && rm -f /tmp/lts* && rm -f /tmp/v2* && rm -f -r /tmp/arm-trusted-firmware-* && rm -f -r /tmp/optee_os-* && rm -f /tmp/plat* && rm -f /tmp/000* && rm -f /tmp/logo.bmp && rm -f /tmp/bl31_param.h && rm -f /tmp/rk3399_def.h && rm -f /tmp/tee.bin && rm -f /tmp/efi.var && rm -f -r U-Boot && cd ..
exit
