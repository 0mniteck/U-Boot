#!/usr/bin/env bash

echo 'CONFIG_SYS_PROMPT="0MNITECK:~$ "' >> defconfig
echo 'CONFIG_LOCALVERSION=" 0MNITECK"' >> defconfig
echo "CONFIG_FIT_SIGNATURE=y" >> defconfig
echo "CONFIG_TEE=y" >> defconfig
echo "CONFIG_OPTEE=y" >> defconfig
echo "CONFIG_OPTEE_TZDRAM_SIZE=0x02000000" >> defconfig
echo "CONFIG_OPTEE_SERVICE_DISCOVERY=y" >> defconfig
echo "CONFIG_BOOTM_OPTEE=y" >> defconfig
echo "CONFIG_OPTEE_TA_SCP03=n" >> defconfig
echo "CONFIG_OPTEE_TA_AVB=n" >> defconfig
echo "CONFIG_CHIMP_OPTEE=n" >> defconfig
