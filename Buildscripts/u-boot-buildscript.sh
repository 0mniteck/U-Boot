#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for dev in $BUILD_LIST
  do
  for loc in $(echo $dev | cut -d':' -f1): $(echo $dev | cut -d':' -f1)-SB:sb- $(echo $dev | cut -d':' -f1)-MU-SB:mutable-sb-
    do
    echo "Unzipping U-Boot for $(echo $dev | cut -d':' -f1)..."
    unzip -q /v$UB_VER.zip -d /$(echo $loc | cut -d':' -f1) > /dev/null
    echo "Entering /$(echo $loc | cut -d':' -f1)/u-boot-$UB_VER"
    pushd /$(echo $loc | cut -d':' -f1)/u-boot-$UB_VER
      make clean
      if [ "$DEV_BUILD" = "yes" ]; then
        ../.././Configs/dev-config.sh
      else
        ../.././Configs/common-config.sh
        if [ "$(echo $loc | cut -d':' -f2)" != "" ]; then
          ../.././Configs/efi-config.sh
          ../.././Configs/$(echo $loc | cut -d':' -f2)config.sh
        fi
      fi
      cp /Includes/efi.var efi.var
      sha512sum --status -c /Includes/efi.var.sum && echo "Deployed efi.var" || exit 1
      cp /Includes/logo.bmp tools/logos/denx.bmp && cp /Includes/logo.bmp drivers/video/u_boot_logo.bmp && echo "Deployed Logo"
      if [ "$(echo $dev | cut -d':' -f2)" = "rockpro64-rk3399_defconfig" ]; then
        ../.././Configs/tpm-config.sh
        cp /Includes/rk3399-rockpro64-u-boot.dtsi arch/arm/dts/rk3399-rockpro64-u-boot.dtsi
        cp /Includes/rk3399-spi1-cs-gpio-slb9670.dtso dts/upstream/src/arm64/rockchip/rk3399-spi1-cs-gpio-slb9670.dtso
        cp /Includes/rk3399-spi1-cs-gpio-slb9670.dtso arch/arm/dts/rk3399-spi1-cs-gpio-slb9670.dtso && echo "Installed TPM Overlay"
      fi
      if [ "$(echo $dev | cut -d':' -f2)" = "pinebook-pro-rk3399_defconfig" ]; then
        cp /Includes/rk3399-pinebook-pro-u-boot.dtsi arch/arm/dts/rk3399-pinebook-pro-u-boot.dtsi && echo "Patched Device Tree Bug"
      fi
      if [ "$(echo $dev | cut -d':' -f2)" = "rock5b-rk3588_defconfig" ] || [ "$(echo $dev | cut -d':' -f2)" = "pinetab2-rk3566_defconfig" ]; then
        ../.././Configs/xpl-config.sh
        if [ "$(echo $dev | cut -d':' -f2)" = "pinetab2-rk3566_defconfig" ]; then
          echo "CONFIG_SPL_MAX_SIZE=0x25800" >> defconfig
        fi
        sed -i '112,117d' arch/arm/mach-rockchip/sdram.c && echo "Deployed Rockchip TPL Bypass"
      fi
      sed -i 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' configs/$(echo $dev | cut -d':' -f2)
      cat defconfig >> configs/$(echo $dev | cut -d':' -f2) && echo "Appended Defconfig"
      cat configs/$(echo $dev | cut -d':' -f2)
      make $(echo $dev | cut -d':' -f2)
      platt=$(echo $(echo $dev | cut -d':' -f1) | cut -d'-' -f2)
      if [ "$platt" = "rk3566" ]; then
        platt=rk3568
      fi
      BL31=/Builds/$platt/bl31.elf FORCE_SOURCE_DATE=1 SOURCE_DATE=$SOURCE_DATE SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH make -j $(nproc) all
      ls -la
      cat simple-bin.map
    popd
    mv /$(echo $loc | cut -d':' -f1)/u-boot-$UB_VER/u-boot-rockchip.bin /$(echo $loc | cut -d':' -f1)/u-boot-rockchip.bin
    mv /$(echo $loc | cut -d':' -f1)/u-boot-$UB_VER/u-boot-rockchip-spi.bin /$(echo $loc | cut -d':' -f1)/u-boot-rockchip-spi.bin
    rm -f -r /$(echo $loc | cut -d':' -f1)/u-boot-$UB_VER
  done
done
echo "# Container Build System: $(uname -o) $(uname -r) $(uname -m) $(lsb_release -ds) $(uname -v)" > /sys.info
