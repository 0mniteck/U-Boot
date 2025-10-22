#!/usr/bin/env bash

echo "CONFIG_CMD_OPTEE_RPMB=y" >> defconfig
echo "CONFIG_SUPPORT_EMMC_RPMB=y" >> defconfig
echo "CONFIG_EFI_MM_COMM_TEE=y" >> defconfig
