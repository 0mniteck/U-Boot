#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  echo "Unzipping optee_os for $plat..."
  unzip -q $OPT_VER.zip -d /$plat > /dev/null
  unzip -q ftpm_$OPT_VER.zip -d /$plat/optee_os-$OPT_VER/ta > /dev/null
  mv /$plat/optee_os-$OPT_VER/ta/optee_ftpm-$OPT_VER /$plat/optee_os-$OPT_VER/ta/optee_ftpm
  unzip -q TPM.zip -d /$plat/TPM > /dev/null
  mv /$plat/TPM/ms-tpm-20-ref-1.83r1/.* /$plat/TPM
  mv /$plat/TPM/ms-tpm-20-ref-1.83r1/* /$plat/TPM
  sed -i '1d;2d' /$plat/optee_os-$OPT_VER/ta/mk/ta_dev_kit.mk
  sed -i "1ism := /ta" /$plat/optee_os-$OPT_VER/ta/mk/ta_dev_kit.mk
  sed -i "1ita-dev-kit-dir := /$plat/optee_os-$OPT_VER" /$plat/optee_os-$OPT_VER/ta/mk/ta_dev_kit.mk
  sed -i "s'/mk/\$(COMPILER_\$(sm)).mk'/mk/gcc.mk'" /$plat/optee_os-$OPT_VER/ta/mk/ta_dev_kit.mk
  sed -i "s'\$(ta-dev-kit-dir\$(sm))/mk/link.mk'/$plat/optee_os-$OPT_VER/ta/link.mk'" /$plat/optee_os-$OPT_VER/ta/mk/ta_dev_kit.mk
  cp /$plat/optee_os-$OPT_VER/ta/mk/ta_dev_kit.mk /$plat/optee_os-$OPT_VER/mk/ta_dev_kit.mk
  # cp /$plat/optee_os-$OPT_VER/ta/mk/build-user-ta.mk /$plat/optee_os-$OPT_VER/mk/ta_dev_kit.mk
  sed -i "s/PLATFORM_FLAVOR ?= rk322x/PLATFORM_FLAVOR ?= $plat/" /$plat/optee_os-$OPT_VER/core/arch/arm/plat-rockchip/conf.mk
  sed -i "s'include core/arch/arm/cpu/cortex-armv8-0.mk'include /$plat/optee_os-$OPT_VER/core/arch/arm/cpu/cortex-armv8-0.mk'" /$plat/optee_os-$OPT_VER/core/arch/arm/plat-rockchip/conf.mk
  cp /$plat/optee_os-$OPT_VER/core/arch/arm/plat-rockchip/conf.mk /$plat/optee_os-$OPT_VER/mk/conf.mk
  pushd /$plat/optee_os-$OPT_VER/ta/optee_ftpm
    rm -f platform/include/*
    cp -r -f /$plat/TPM/TPMCmd/Platform/include/* platform/include/
    sed -i "33iglobal-incdirs_ext-y += /$plat/optee_os-$OPT_VER/ta/optee_ftpm/platform/include/prototypes" sub.mk
    sed -i "s'/TPMCmd/tpm/include/prototypes'/TPMCmd/tpm/include/private/prototypes'" sub.mk
    sed -i "37iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/public/prototypes" sub.mk
    sed -i "38iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/platform_interface/prototypes" sub.mk
    sed -i "s'global-incdirs-y += include'global-incdirs_ext-y += /$plat/optee_os-$OPT_VER/ta/optee_ftpm/include'" sub.mk
    sed -i "s'global-incdirs-y += reference/include'global-incdirs_ext-y += /$plat/optee_os-$OPT_VER/ta/optee_ftpm/reference/include'" sub.mk
    sed -i "s'global-incdirs-y += platform/include'global-incdirs_ext-y += /$plat/optee_os-$OPT_VER/ta/optee_ftpm/platform/include'" sub.mk
    sed -i "s'<TpmConfiguration'</$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration'" platform/include/Platform.h
    sed -i "s'<public'</$plat/TPM/TPMCmd/tpm/include/public'" platform/include/Platform.h
    sed -i "s'<platform_interface'</$plat/TPM/TPMCmd/tpm/include/platform_interface'" platform/include/Platform.h
    # sed -i "5d;6d" platform/include/Platform.h
    cat platform/include/Platform.h
    mkdir ../../include
    rm -f /$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration/TpmProfile.h
    touch /$plat/TPM/TPMCmd/TpmConfiguration/TpmConfiguration/TpmProfile.h
    make -j $(nproc) TA_DEV_KIT_DIR=/$plat/optee_os-$OPT_VER CFG_MS_TPM_20_REF=/$plat/TPM CFG_TA_MEASURED_BOOT=y CFG_TA_EVENT_LOG_SIZE=65536 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- VERBOSE=1
  popd
  echo "Entering /$plat/optee_os-$OPT_VER"
  pushd /$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- CFG_EARLY_CONSOLE_BAUDRATE=115200
    ls -la /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/core/
  popd
done
