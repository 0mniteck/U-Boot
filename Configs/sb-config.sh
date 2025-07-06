#!/usr/bin/env bash

echo "CONFIG_EFI_VARIABLE_NO_STORE=y" >> defconfig
echo "CONFIG_EFI_VARIABLES_PRESEED=y" >> defconfig
echo 'CONFIG_EFI_VAR_SEED_FILE="efi.var"' >> defconfig
echo "CONFIG_ENV_IS_NOWHERE=y" >> defconfig
