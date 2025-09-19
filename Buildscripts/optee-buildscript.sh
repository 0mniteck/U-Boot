#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  unzip -q $OPT_VER.zip -d /$plat > /dev/null
  unzip -q ftpm_$OPT_VER.zip -d /$plat > /dev/null
  unzip -q TPM.zip -d /$plat > /dev/null
  unzip -q SSL.zip -d /$plat > /dev/null
  mv /$plat/ms-tpm-20-ref-1.83r1 /$plat/TPM
  mkdir -p /$plat/openssl/
  mv /$plat/openssl-openssl-$SSL_VER/crypto /$plat/openssl/openssl
  pushd /$plat/optee_os-$OPT_VER
    make -j $(nproc) PLATFORM=rockchip-$plat CFG_ARM64_core=y CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- CFG_USER_TA_TARGETS=ta_arm64 CFG_EARLY_CONSOLE_BAUDRATE=115200 EARLY_TA_PATHS=/$plat/optee_ftpm-$OPT_VER/out/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf ta_dev_kit
  popd
  pushd /$plat/optee_ftpm-$OPT_VER
    rm -r -f platform/*
    mkdir platform/include
    cp -f /$plat/TPM/TPMCmd/Platform/src/* platform/
    cp -r -f /$plat/TPM/TPMCmd/Platform/include/* platform/include/
    pushd /$plat/TPM/TPMCmd/
      sed -i "52d;65d;78d;103d;120d;126d;207d" TpmConfiguration/TpmConfiguration/TpmBuildSwitches.h
      sed -i "44d;48d;128d;149d" TpmConfiguration/TpmConfiguration/TpmProfile_Common.h
      sed -i "s'0x30100000L'0x40100000L'" tpm/cryptolibs/Ossl/include/Ossl/BnToOsslMath.h
    popd
    sed -i "s'_plat__NVEnable(void \*platParameter)'_plat__NVEnable(void\*  platParameter, size_t paramSize)'" include/fTPM.h
    sed -i "s'TPM_Manufacture(bool firstTime)'TPM_Manufacture(int firstTime)'" include/fTPM.h
    sed -i "s'_plat__NVDisable(void)'_plat__NVDisable(void\*  platParameter, size_t paramSize)'" include/fTPM.h
    sed -i "s'4096'(4096-0x80)'" include/fTPM.h
    sed -i "s'(_plat__NVEnable(NULL))'(_plat__NVEnable(NULL,0))'" fTPM.c
    sed -i "s'_plat__NVDisable()'_plat__NVDisable(NULL,0)'" fTPM.c
    sed -i "68,70d;" fTPM.c
    sed -i "178d" /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64/include/util.h
    sed -i "27d" /$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64/include/limits.h
    sed -i "70d" platform/RunCommand.c
    sed -i '70i        fprintf(stderr, "unk s location code");' platform/RunCommand.c
    sed -i "s'ECC_CURVE_DATA'TPM_ECC_CURVE'" include/TEE/TpmToTEEMath.h
    sed -i "3d;12d;36d;83,97d;104,105d;110,309d" sub.mk
    sed -i "11iexport CC=gcc" sub.mk
    sed -i "s'-DMATH_LIB=TEE'-DMATH_LIB=TpmBigNum'" sub.mk
    sed -i "'s'cppflags-y += -D_ARM_ -DFAIL_TRACE=NO'cppflags-y += -D_ARM_ -DFAIL_TRACE=NO -DBN_MATH_LIB=Ossl'" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/cryptolibs/TpmBigNum/include" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/cryptolibs/Ossl/include" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/cryptolibs/common/include" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/cryptolibs" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/TpmConfiguration/TpmConfiguration" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/TpmConfiguration" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/platform_interface/" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/platform_interface/prototypes" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/private" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/private/prototypes" sub.mk
    sed -i "35iglobal-incdirs_ext-y += \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/include/public" sub.mk
    sed -i "35iglobal-incdirs_ext-y += /$plat/openssl" sub.mk
    sed -i "35iglobal-incdirs_ext-y += /usr/include/aarch64-linux-gnu" sub.mk
    sed -i "35iglobal-incdirs_ext-y += /usr/include" sub.mk
    sed -i "53icflags-y += -Wno-strict-aliasing" sub.mk
    sed -i "53icflags-y += -Wno-nested-externs" sub.mk
    sed -i "75icflags-platform/Clock.c-y += -Wno-missing-declarations" sub.mk
    sed -i "75icflags-platform/Clock.c-y += -Wno-implicit-function-declaration" sub.mk
    sed -i "75icflags-platform/Entropy.c-y += -Wno-implicit-function-declaration" sub.mk
    sed -i "75icflags-platform/RunCommand.c-y += -Wno-implicit-function-declaration" sub.mk
    sed -i "75icflags-platform/RunCommand.c-y += -Wno-missing-declarations" sub.mk
    sed -i "75icflags-platform/RunCommand.c-y += -Wno-builtin-declaration-mismatch" sub.mk
    sed -i "75icflags-platform/NVMem.c-y += -Wno-int-conversion" sub.mk
    sed -i "75icflags-platform/NVMem.c-y += -Wno-missing-declarations" sub.mk
    sed -i "75icflags-platform/PlatformPcr.c-y += -Wno-old-style-definition" sub.mk
    sed -i "75icflags-platform/PlatformPcr.c-y += -Wno-sign-compare" sub.mk
    sed -i "75icflags-platform/VendorInfo.c-y += -Wno-missing-prototypes" sub.mk
    sed -i "75icflags-platform/VendorInfo.c-y += -Wno-old-style-definition" sub.mk
    sed -i "75icflags-platform/VendorInfo.c-y += -Wno-discarded-qualifiers" sub.mk
    sed -i "75icflags-platform/VendorInfo.c-y += -Wno-missing-declarations" sub.mk
    sed -i "112i \\
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
echo "srcs_ext_base-y := \$(CFG_MS_TPM_20_REF)/TPMCmd/tpm/src/
srcs_ext-y += ./../cryptolibs/TpmBigNum/BnConvert.c
srcs_ext-y += ./../cryptolibs/TpmBigNum/BnEccConstants.c
srcs_ext-y += ./../cryptolibs/TpmBigNum/BnMath.c
srcs_ext-y += ./../cryptolibs/TpmBigNum/BnMemory.c
srcs_ext-y += ./../cryptolibs/TpmBigNum/BnUtil.c
srcs_ext-y += ./../cryptolibs/TpmBigNum/TpmBigNumThunks.c
srcs_ext-y += ./../cryptolibs/Ossl/BnToOsslMath.c
srcs_ext-y += ./../cryptolibs/Ossl/TpmToOsslSupport.c
 
srcs-y += tee/TpmToTEEMath.c
srcs-y += tee/TpmToTEESupport.c
srcs-y += tee/TpmToTEESym.c
 
srcs_ext-y += X509/TpmASN1.c
srcs_ext-y += X509/X509_ECC.c
srcs_ext-y += X509/X509_RSA.c
srcs_ext-y += X509/X509_spt.c
srcs_ext-y += command/Asymmetric/ECC_Decrypt.c
srcs_ext-y += command/Asymmetric/ECC_Encrypt.c
srcs_ext-y += command/Asymmetric/ECC_Parameters.c
srcs_ext-y += command/Asymmetric/ECDH_KeyGen.c
srcs_ext-y += command/Asymmetric/ECDH_ZGen.c
srcs_ext-y += command/Asymmetric/EC_Ephemeral.c
srcs_ext-y += command/Asymmetric/RSA_Decrypt.c
srcs_ext-y += command/Asymmetric/RSA_Encrypt.c
srcs_ext-y += command/Asymmetric/ZGen_2Phase.c
srcs_ext-y += command/AttachedComponent/AC_GetCapability.c
srcs_ext-y += command/AttachedComponent/AC_Send.c
srcs_ext-y += command/AttachedComponent/AC_spt.c
srcs_ext-y += command/AttachedComponent/Policy_AC_SendSelect.c
srcs_ext-y += command/Attestation/Attest_spt.c
srcs_ext-y += command/Attestation/Certify.c
srcs_ext-y += command/Attestation/CertifyCreation.c
srcs_ext-y += command/Attestation/CertifyX509.c
srcs_ext-y += command/Attestation/GetCommandAuditDigest.c
srcs_ext-y += command/Attestation/GetSessionAuditDigest.c
srcs_ext-y += command/Attestation/GetTime.c
srcs_ext-y += command/Attestation/Quote.c
srcs_ext-y += command/Capability/GetCapability.c
srcs_ext-y += command/Capability/SetCapability.c
srcs_ext-y += command/Capability/TestParms.c
srcs_ext-y += command/ClockTimer/ACT_SetTimeout.c
srcs_ext-y += command/ClockTimer/ACT_spt.c
srcs_ext-y += command/ClockTimer/ClockRateAdjust.c
srcs_ext-y += command/ClockTimer/ClockSet.c
srcs_ext-y += command/ClockTimer/ReadClock.c
srcs_ext-y += command/CommandAudit/SetCommandCodeAuditStatus.c
srcs_ext-y += command/Context/ContextLoad.c
srcs_ext-y += command/Context/ContextSave.c
srcs_ext-y += command/Context/Context_spt.c
srcs_ext-y += command/Context/EvictControl.c
srcs_ext-y += command/Context/FlushContext.c
srcs_ext-y += command/DA/DictionaryAttackLockReset.c
srcs_ext-y += command/DA/DictionaryAttackParameters.c
srcs_ext-y += command/Duplication/Duplicate.c
srcs_ext-y += command/Duplication/Import.c
srcs_ext-y += command/Duplication/Rewrap.c
srcs_ext-y += command/EA/PolicyAuthValue.c
srcs_ext-y += command/EA/PolicyAuthorize.c
srcs_ext-y += command/EA/PolicyAuthorizeNV.c
srcs_ext-y += command/EA/PolicyCapability.c
srcs_ext-y += command/EA/PolicyCommandCode.c
srcs_ext-y += command/EA/PolicyCounterTimer.c
srcs_ext-y += command/EA/PolicyCpHash.c
srcs_ext-y += command/EA/PolicyDuplicationSelect.c
srcs_ext-y += command/EA/PolicyGetDigest.c
srcs_ext-y += command/EA/PolicyLocality.c
srcs_ext-y += command/EA/PolicyNV.c
srcs_ext-y += command/EA/PolicyNameHash.c
srcs_ext-y += command/EA/PolicyNvWritten.c
srcs_ext-y += command/EA/PolicyOR.c
srcs_ext-y += command/EA/PolicyPCR.c
srcs_ext-y += command/EA/PolicyParameters.c
srcs_ext-y += command/EA/PolicyPassword.c
srcs_ext-y += command/EA/PolicyPhysicalPresence.c
srcs_ext-y += command/EA/PolicySecret.c
srcs_ext-y += command/EA/PolicySigned.c
srcs_ext-y += command/EA/PolicyTemplate.c
srcs_ext-y += command/EA/PolicyTicket.c
srcs_ext-y += command/EA/Policy_spt.c
srcs_ext-y += command/Ecdaa/Commit.c
srcs_ext-y += command/FieldUpgrade/FieldUpgradeData.c
srcs_ext-y += command/FieldUpgrade/FieldUpgradeStart.c
srcs_ext-y += command/FieldUpgrade/FirmwareRead.c
srcs_ext-y += command/HashHMAC/EventSequenceComplete.c
srcs_ext-y += command/HashHMAC/HMAC_Start.c
srcs_ext-y += command/HashHMAC/HashSequenceStart.c
srcs_ext-y += command/HashHMAC/MAC_Start.c
srcs_ext-y += command/HashHMAC/SequenceComplete.c
srcs_ext-y += command/HashHMAC/SequenceUpdate.c
srcs_ext-y += command/Hierarchy/ChangeEPS.c
srcs_ext-y += command/Hierarchy/ChangePPS.c
srcs_ext-y += command/Hierarchy/Clear.c
srcs_ext-y += command/Hierarchy/ClearControl.c
srcs_ext-y += command/Hierarchy/CreatePrimary.c
srcs_ext-y += command/Hierarchy/HierarchyChangeAuth.c
srcs_ext-y += command/Hierarchy/HierarchyControl.c
srcs_ext-y += command/Hierarchy/SetPrimaryPolicy.c
srcs_ext-y += command/Misc/PP_Commands.c
srcs_ext-y += command/Misc/SetAlgorithmSet.c
srcs_ext-y += command/NVStorage/NV_Certify.c
srcs_ext-y += command/NVStorage/NV_ChangeAuth.c
srcs_ext-y += command/NVStorage/NV_DefineSpace.c
srcs_ext-y += command/NVStorage/NV_DefineSpace2.c
srcs_ext-y += command/NVStorage/NV_Extend.c
srcs_ext-y += command/NVStorage/NV_GlobalWriteLock.c
srcs_ext-y += command/NVStorage/NV_Increment.c
srcs_ext-y += command/NVStorage/NV_Read.c
srcs_ext-y += command/NVStorage/NV_ReadLock.c
srcs_ext-y += command/NVStorage/NV_ReadPublic.c
srcs_ext-y += command/NVStorage/NV_ReadPublic2.c
srcs_ext-y += command/NVStorage/NV_SetBits.c
srcs_ext-y += command/NVStorage/NV_UndefineSpace.c
srcs_ext-y += command/NVStorage/NV_UndefineSpaceSpecial.c
srcs_ext-y += command/NVStorage/NV_Write.c
srcs_ext-y += command/NVStorage/NV_WriteLock.c
srcs_ext-y += command/NVStorage/NV_spt.c
srcs_ext-y += command/Object/ActivateCredential.c
srcs_ext-y += command/Object/Create.c
srcs_ext-y += command/Object/CreateLoaded.c
srcs_ext-y += command/Object/Load.c
srcs_ext-y += command/Object/LoadExternal.c
srcs_ext-y += command/Object/MakeCredential.c
srcs_ext-y += command/Object/ObjectChangeAuth.c
srcs_ext-y += command/Object/Object_spt.c
srcs_ext-y += command/Object/ReadPublic.c
srcs_ext-y += command/Object/Unseal.c
srcs_ext-y += command/PCR/PCR_Allocate.c
srcs_ext-y += command/PCR/PCR_Event.c
srcs_ext-y += command/PCR/PCR_Extend.c
srcs_ext-y += command/PCR/PCR_Read.c
srcs_ext-y += command/PCR/PCR_Reset.c
srcs_ext-y += command/PCR/PCR_SetAuthPolicy.c
srcs_ext-y += command/PCR/PCR_SetAuthValue.c
srcs_ext-y += command/Random/GetRandom.c
srcs_ext-y += command/Random/StirRandom.c
srcs_ext-y += command/Session/PolicyRestart.c
srcs_ext-y += command/Session/StartAuthSession.c
srcs_ext-y += command/Signature/Sign.c
srcs_ext-y += command/Signature/VerifySignature.c
srcs_ext-y += command/Startup/Shutdown.c
srcs_ext-y += command/Startup/Startup.c
srcs_ext-y += command/Symmetric/EncryptDecrypt.c
srcs_ext-y += command/Symmetric/EncryptDecrypt2.c
srcs_ext-y += command/Symmetric/EncryptDecrypt_spt.c
srcs_ext-y += command/Symmetric/HMAC.c
srcs_ext-y += command/Symmetric/Hash.c
srcs_ext-y += command/Symmetric/MAC.c
srcs_ext-y += command/Testing/GetTestResult.c
srcs_ext-y += command/Testing/IncrementalSelfTest.c
srcs_ext-y += command/Testing/SelfTest.c
srcs_ext-y += command/Vendor/Vendor_TCG_Test.c
srcs_ext-y += crypt/AlgorithmTests.c
srcs_ext-y += crypt/CryptCmac.c
srcs_ext-y += crypt/CryptEccCrypt.c
srcs_ext-y += crypt/CryptEccData.c
srcs_ext-y += crypt/CryptEccKeyExchange.c
srcs_ext-y += crypt/CryptEccMain.c
srcs_ext-y += crypt/CryptEccSignature.c
srcs_ext-y += crypt/CryptHash.c
srcs_ext-y += crypt/CryptPrime.c
srcs_ext-y += crypt/CryptPrimeSieve.c
srcs_ext-y += crypt/CryptRand.c
srcs_ext-y += crypt/CryptRsa.c
srcs_ext-y += crypt/CryptSelfTest.c
srcs_ext-y += crypt/CryptSmac.c
srcs_ext-y += crypt/CryptSym.c
srcs_ext-y += crypt/CryptUtil.c
srcs_ext-y += crypt/PrimeData.c
srcs_ext-y += crypt/RsaKeyCache.c
srcs_ext-y += crypt/Ticket.c
srcs_ext-y += crypt/ecc/TpmEcc_Signature_ECDAA.c
srcs_ext-y += crypt/ecc/TpmEcc_Signature_ECDSA.c
srcs_ext-y += crypt/ecc/TpmEcc_Signature_SM2.c
srcs_ext-y += crypt/ecc/TpmEcc_Signature_Schnorr.c
srcs_ext-y += crypt/ecc/TpmEcc_Signature_Util.c
srcs_ext-y += crypt/ecc/TpmEcc_Util.c
srcs_ext-y += crypt/math/TpmMath_Debug.c
srcs_ext-y += crypt/math/TpmMath_Util.c
srcs_ext-y += events/_TPM_Hash_Data.c
srcs_ext-y += events/_TPM_Hash_End.c
srcs_ext-y += events/_TPM_Hash_Start.c
srcs_ext-y += events/_TPM_Init.c
srcs_ext-y += main/CommandDispatcher.c
srcs_ext-y += main/ExecCommand.c
srcs_ext-y += main/SessionProcess.c
srcs_ext-y += subsystem/CommandAudit.c
srcs_ext-y += subsystem/DA.c
srcs_ext-y += subsystem/Hierarchy.c
srcs_ext-y += subsystem/NvDynamic.c
srcs_ext-y += subsystem/NvReserved.c
srcs_ext-y += subsystem/Object.c
srcs_ext-y += subsystem/PCR.c
srcs_ext-y += subsystem/PP.c
srcs_ext-y += subsystem/Session.c
srcs_ext-y += subsystem/Time.c
srcs_ext-y += support/AlgorithmCap.c
srcs_ext-y += support/Bits.c
srcs_ext-y += support/CommandCodeAttributes.c
srcs_ext-y += support/Entity.c
srcs_ext-y += support/Global.c
srcs_ext-y += support/Handle.c
srcs_ext-y += support/IoBuffers.c
srcs_ext-y += support/Locality.c
srcs_ext-y += support/Manufacture.c
srcs_ext-y += support/Marshal.c
srcs_ext-y += support/MathOnByteBuffers.c
srcs_ext-y += support/Memory.c
srcs_ext-y += support/Power.c
srcs_ext-y += support/PropertyCap.c
srcs_ext-y += support/Response.c
srcs_ext-y += support/ResponseCodeProcessing.c
srcs_ext-y += support/TableDrivenMarshal.c
srcs_ext-y += support/TableMarshalData.c
srcs_ext-y += support/TpmFail.c
srcs_ext-y += support/TpmSizeChecks.c" >> sub.mk
    cat sub.mk
    make -j $(nproc) VERBOSE=1 TA_DEV_KIT_DIR=/$plat/optee_os-$OPT_VER/out/arm-plat-rockchip/export-ta_arm64 CFG_MS_TPM_20_REF=/$plat/TPM CFG_TA_MEASURED_BOOT=y CFG_USER_TA_TARGETS=ta_arm64 CFG_TA_EVENT_LOG_SIZE=65536 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- O=out
    read -p "Waiting fot user..."
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
