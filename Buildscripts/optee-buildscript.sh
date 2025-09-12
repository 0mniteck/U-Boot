#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  unzip -q $OPT_VER.zip -d /$plat > /dev/null
  unzip -q ftpm_$OPT_VER.zip -d /$plat > /dev/null
  unzip -q TPM.zip -d /$plat/TPM > /dev/null
  mv /$plat/TPM/ms-tpm-20-ref-1.83r1/.* /$plat/TPM
  mv /$plat/TPM/ms-tpm-20-ref-1.83r1/* /$plat/TPM
  pushd /$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- CFG_USER_TA_TARGETS=ta_arm64 CFG_EARLY_CONSOLE_BAUDRATE=115200 EARLY_TA_PATHS=/$plat/optee_ftpm-$OPT_VER/out/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf ta_dev_kit
    ls -la /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64
    ls -la /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64/mk
    ls -la /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64/ta
  popd
  pushd /$plat/optee_ftpm-$OPT_VER
    rm -f platform/include/*
    cp -r -f /$plat/TPM/TPMCmd/Platform/include/* platform/include/
    #rm -f /$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration/TpmProfile.h
    #touch /$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration/TpmProfile.h
    make -j $(nproc) TA_DEV_KIT_DIR=/$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64 CFG_MS_TPM_20_REF=/$plat/TPM CFG_TA_MEASURED_BOOT=y CFG_USER_TA_TARGETS=ta_arm64 CFG_TA_EVENT_LOG_SIZE=65536 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- O=out
  popd
  pushd /$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- CFG_USER_TA_TARGETS=ta_arm64 CFG_EARLY_CONSOLE_BAUDRATE=115200 EARLY_TA_PATHS=/$plat/optee_ftpm-$OPT_VER/out/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf
  popd
done
mkdir /NOTPM
for plat in $ARCHS
do
  unzip -q $OPT_VER.zip -d /NOTPM/$plat > /dev/null
  pushd /NOTPM/$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- CFG_EARLY_CONSOLE_BAUDRATE=115200
    ls -la /NOTPM/$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/core/
  popd
done
