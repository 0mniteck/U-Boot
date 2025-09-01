#!/usr/bin/env bash

echo "CONFIG_STACKPROTECTOR=y" >> defconfig
echo "CONFIG_BOOTEFI_HELLO_COMPILE=n" >> defconfig
echo "CONFIG_BOOTEFI_TESTAPP_COMPILE=n" >> defconfig
echo 'CONFIG_BOOTCOMMAND="efiload; reset;"' >> defconfig

echo "CONFIG_ECDSA_VERIFY=y" >> defconfig
echo "CONFIG_SPL_ECDSA_VERIFY=y" >> defconfig
echo "CONFIG_TOOLS_MKEFICAPSULE=n" >> defconfig
echo "CONFIG_TOOLS_SHA1=n" >> defconfig
echo "CONFIG_SHA1=n" >> defconfig
echo "CONFIG_SHA1_LEGACY=n" >> defconfig
echo "CONFIG_TOOLS_MD5=n" >> defconfig
echo "CONFIG_MD5=n" >> defconfig
echo "CONFIG_MD5_LEGACY=n" >> defconfig
echo "CONFIG_CRC32=n" >> defconfig
echo "CONFIG_SPL_CRC32=n" >> defconfig
echo "CONFIG_TOOLS_CRC32=n" >> defconfig
echo "CONFIG_CRC8=n" >> defconfig
echo "CONFIG_SPL_CRC8=n" >> defconfig
echo "CONFIG_CRC16=n" >> defconfig
echo "CONFIG_TOOLS_CRC16=n" >> defconfig

echo "CONFIG_CMD_EXPORTENV=n" >> defconfig
echo "CONFIG_CMD_IMPORTENV=n" >> defconfig
echo "CONFIG_CMD_EDITENV=n" >> defconfig
echo "CONFIG_CMD_SAVEENV=n" >> defconfig
echo "CONFIG_CMD_SOURCE=n" >> defconfig
echo "CONFIG_SAVEENV=n" >> defconfig
echo "CONFIG_ENV_IS_IN_SPI_FLASH=n" >> defconfig

echo "CONFIG_BOOTMETH_EXTLINUX_PXE=n" >> defconfig
echo "CONFIG_CMD_NET=n" >> defconfig
echo "CONFIG_CMD_BOOTP=n" >> defconfig
echo "CONFIG_BOOTP_BOOTPATH=n" >> defconfig
echo "CONFIG_BOOTP_DNS=n" >> defconfig
echo "CONFIG_BOOTP_GATEWAY=n" >> defconfig
echo "CONFIG_BOOTP_HOSTNAME=n" >> defconfig
echo "CONFIG_BOOTP_SUBNETMASK=n" >> defconfig
echo "CONFIG_BOOTP_PXE=n" >> defconfig
echo "CONFIG_NET_TFTP_VARS=n" >> defconfig
echo "CONFIG_CMD_DHCP=n" >> defconfig
echo "CONFIG_CMD_PING=n" >> defconfig
echo "CONFIG_CMD_TFTPBOOT=n" >> defconfig
echo "CONFIG_CMD_PXE=n" >> defconfig

echo "CONFIG_LEGACY_IMAGE_FORMAT=n" >> defconfig
echo "CONFIG_BOOTDEV_ETH=n" >> defconfig
echo "CONFIG_CMD_BOOTD=n" >> defconfig
echo "CONFIG_CMD_BOOTDEV=n" >> defconfig
echo "CONFIG_CMD_BOOTFLOW=n" >> defconfig
echo "CONFIG_CMD_BOOTFLOW_FULL=n" >> defconfig

echo "CONFIG_BOOTM_ELF=n" >> defconfig
echo "CONFIG_CMD_BOOTI=n" >> defconfig
echo "CONFIG_BOOTM_LINUX=n" >> defconfig
echo "CONFIG_BOOTM_NETBSD=n" >> defconfig
echo "CONFIG_BOOTM_PLAN9=n" >> defconfig
echo "CONFIG_BOOTM_RTEMS=n" >> defconfig
echo "CONFIG_BOOTM_VXWORKS=n" >> defconfig
echo "CONFIG_CMD_GO=n" >> defconfig
echo "CONFIG_CMD_RUN=n" >> defconfig
echo "CONFIG_CMD_EXT2=n" >> defconfig

echo "CONFIG_CMD_LOADB=n" >> defconfig
echo "CONFIG_CMD_LOADS=n" >> defconfig

echo "CONFIG_SHOW_BOOT_PROGRESS=y" >> defconfig
echo "CONFIG_SPL_SHOW_BOOT_PROGRESS=y" >> defconfig

echo "CONFIG_SPL_SYSINFO=y" >> defconfig
echo "CONFIG_SYSINFO_EXTRA=y" >> defconfig

echo "CONFIG_VIDEO_ROCKCHIP_MAX_XRES=7680" >> defconfig
echo "CONFIG_VIDEO_ROCKCHIP_MAX_YRES=4320" >> defconfig

# echo "CONFIG_DISABLE_CONSOLE=y" >> defconfig

# echo "CONFIG_MBEDTLS_LIB=y" >> defconfig
# echo "CONFIG_SPL_MBEDTLS_LIB=y" >> defconfig

# echo "CONFIG_CMD_MII=?" >> defconfig
# echo "CONFIG_CMD_MDIO=?" >> defconfig

# echo "CONFIG_CMD_BOOTMETH=?" >> defconfig
# echo "CONFIG_CMD_BOOTSTD=?" >> defconfig

# echo "CONFIG_CMD_IMI=?" >> defconfig
# echo "CONFIG_CMD_XIMG=?" >> defconfig

# echo "CONFIG_AUTOBOOT_USE_MENUKEY=?" >> defconfig
# echo "CONFIG_CMD_BOOTMENU=?" >> defconfig

# echo "CONFIG_MTD=?" >> defconfig
# echo "CONFIG_USB_GADGET=?" >> defconfig
# echo "CONFIG_SYS_WHITE_ON_BLACK=?" >> defconfig
