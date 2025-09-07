#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  echo "Unzipping optee_os for $plat..."
  unzip -q $OPT_VER.zip -d /$plat > /dev/null
  unzip -q ftpm_$OPT_VER.zip -d /$plat/optee_os-$OPT_VER/ta > /dev/null
  mv /$plat/optee_os-$OPT_VER/ta/optee_ftpm-$OPT_VER /$plat/optee_os-$OPT_VER/ta/optee_ftpm
  unzip -q TPM.zip -d /TPM > /dev/null
  mv /TPM/ms-tpm-20-ref-1.83r1/.* /TPM
  echo "Entering /$plat/optee_os-$OPT_VER"
  pushd /$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- \
    CFG_MS_TPM_20_REF="/TPM/" CFG_TA_MEASURED_BOOT=y CFG_TA_EVENT_LOG_SIZE=65536
    ls -la /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/core/
  popd
done
