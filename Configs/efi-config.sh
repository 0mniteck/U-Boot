#!/usr/bin/env bash

echo "CONFIG_BOOTM_EFI=y" >> defconfig
echo "CONFIG_EFI_SECURE_BOOT=y" >> defconfig
echo "CONFIG_EFI_LOADER=y" >> defconfig
echo "CONFIG_CMD_BOOTEFI=y" >> defconfig
