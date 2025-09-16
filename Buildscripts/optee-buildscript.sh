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
  popd
  pushd /$plat/optee_ftpm-$OPT_VER
    rm -r -f platform/*
    mkdir platform/include
    cp -f /$plat/TPM/TPMCmd/Platform/src/* platform/
    cp -r -f /$plat/TPM/TPMCmd/Platform/include/* platform/include/
    pushd /$plat/TPM/TPMCmd/
      find . -type f -exec sed -i "s'<TpmConfiguration'</$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration'" {} \;
      sed -i "52d;65d;78d;103d;120d;126d;207d" TpmConfiguration/TpmConfiguration/TpmBuildSwitches.h
      sed -i "44d;48d;128d;149d" TpmConfiguration/TpmConfiguration/TpmProfile_Common.h
    popd
    sed -i "s'<TpmConfiguration'</$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration'" platform/include/Platform.h
    sed -i "s'<platform_interface'</$plat/TPM/TPMCmd/tpm/include/platform_interface'" platform/include/Platform.h
    sed -i "s'<public'</$plat/TPM/TPMCmd/tpm/include/public'" platform/include/Platform.h
    sed -i "s'<TpmProfile.h'</$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration/TpmProfile.h'" include/fTPM.h
    sed -i "s'_plat__NVEnable(void \*platParameter)'_plat__NVEnable(void\*  platParameter, size_t paramSize)'" include/fTPM.h
    sed -i "s'TPM_Manufacture(bool firstTime)'TPM_Manufacture(int firstTime)'" include/fTPM.h
    sed -i "s'_plat__NVDisable(void)'_plat__NVDisable(void\*  platParameter, size_t paramSize)'" include/fTPM.h
    sed -i "s'4096'(4096-0x80)'" include/fTPM.h
    sed -i "s'(_plat__NVEnable(NULL))'(_plat__NVEnable(NULL,0))'" fTPM.c
    sed -i "s'_plat__NVDisable()'_plat__NVDisable(NULL,0)'" fTPM.c
    sed -i "68,70d;" fTPM.c
    sed -i "178d" /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64/include/util.h
    sed -i "20i#define s_locationCode" platform/RunCommand.c
    sed -i "65d" platform/Clock.c
    sed -i "9i#include <time.h>" platform/Clock.c
    sed -i "9i#include <sys/time.h>" platform/Clock.c
    sed -i "14d" platform/NVMem.c
    sed -i "12i#include <stdio.h>" platform/NVMem.c
    sed -i "12d;83,97d;104d;105d" sub.mk
    sed -i "46icflags-y += -Wno-missing-include-dirs" sub.mk
    sed -i "60icflags-platform/Clock.c-y += -Wno-nested-externs" sub.mk
    sed -i "60icflags-platform/Clock.c-y += -Wno-missing-declarations" sub.mk
    sed -i "60icflags-platform/Clock.c-y += -Wno-implicit-function-declaration" sub.mk
    sed -i "60icflags-platform/Entropy.c-y += -Wno-nested-externs" sub.mk
    sed -i "60icflags-platform/Entropy.c-y += -Wno-implicit-function-declaration" sub.mk
    sed -i "60icflags-platform/RunCommand.c-y += -Wno-implicit-function-declaration" sub.mk
    sed -i "60icflags-platform/RunCommand.c-y += -Wno-missing-declarations" sub.mk
    sed -i "60icflags-platform/RunCommand.c-y += -Wno-builtin-declaration-mismatch" sub.mk
    sed -i "60icflags-platform/NVMem.c-y += -Wno-int-conversion" sub.mk
    sed -i "60icflags-platform/NVMem.c-y += -Wno-missing-declarations" sub.mk
    sed -i "60icflags-platform/PlatformPcr.c-y += -Wno-old-style-definition" sub.mk
    sed -i "60icflags-platform/PlatformPcr.c-y += -Wno-sign-compare" sub.mk
    sed -i "60icflags-platform/VendorInfo.c-y += -Wno-missing-prototypes" sub.mk
    sed -i "60icflags-platform/VendorInfo.c-y += -Wno-old-style-definition" sub.mk
    sed -i "60icflags-platform/VendorInfo.c-y += -Wno-discarded-qualifiers" sub.mk
    sed -i "60icflags-platform/VendorInfo.c-y += -Wno-missing-declarations" sub.mk
    sed -i "83i \\
srcs-y += platform/Cancel.c\\
srcs-y += platform/Clock.c\\
srcs-y += platform/DebugHelpers.c\\
srcs-y += platform/Entropy.c\\
srcs-y += platform/ExtraData.c\\
srcs-y += platform/LocalityPlat.c\\
srcs-y += platform/NVMem.c\\
srcs-y += platform/PPPlat.c\\
srcs-y += platform/PlatformACT.c\\
srcs-y += platform/PlatformData.c\\
srcs-y += platform/PlatformPcr.c\\
srcs-y += platform/PowerPlat.c\\
srcs-y += platform/RunCommand.c\\
srcs-y += platform/Unique.c\\
srcs-y += platform/VendorInfo.c" sub.mk
    make -j $(nproc) MEASURED_BOOT=y TA_DEV_KIT_DIR=/$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64 CFG_MS_TPM_20_REF=/$plat/TPM CFG_TA_MEASURED_BOOT=y CFG_USER_TA_TARGETS=ta_arm64 CFG_TA_EVENT_LOG_SIZE=65536 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- O=out
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
