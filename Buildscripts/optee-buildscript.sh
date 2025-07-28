#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  echo "Unzipping optee_os for $plat..."
  unzip -q $OPT_VER.zip -d /$plat > /dev/null
  echo "Entering /$plat/optee_os-$OPT_VER"
  pushd /$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu-
    ls -la /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/core/
  popd
done
