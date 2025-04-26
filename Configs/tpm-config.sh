#!/usr/bin/env bash

echo 'CONFIG_OF_OVERLAY_LIST="rockchip/rk3399-spi1-cs-gpio-slb9670"' >> defconfig
echo "CONFIG_TPM=y" >> defconfig
echo "CONFIG_TPM_V1=n" >> defconfig
echo "CONFIG_TPM_V2=y" >> defconfig
echo "CONFIG_TPM2_TIS_SPI=y" >> defconfig
echo "CONFIG_SOFT_SPI=y" >> defconfig
echo "CONFIG_CMD_TPM=y" >> defconfig
echo "CONFIG_CMD_SPI=y" >> defconfig
echo "CONFIG_CMD_TPM_TEST=y" >> defconfig
# echo "CONFIG_TPM_RNG=y" >> defconfig
# echo "CONFIG_TPM_TIS_INFINEON=y" >> defconfig
# echo "CONFIG_TPL_TPM=y" >> defconfig
# echo "CONFIG_SPL_TPM=y" >> defconfig
# echo 'CONFIG_DEVICE_TREE_INCLUDES="rk3399-spi1-cs-gpio-slb9670.dtso"' >> defconfig
