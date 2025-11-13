#!/usr/bin/env bash
for plat in $ARCHS
do
  unzip -q $ATF_VER.zip -d /$plat > /dev/null
  unzip -q mbedtls-$MTLS_VER.zip -d /$plat > /dev/null
  pushd /$plat/arm-trusted-firmware-$ATF_VER
    make realclean && make BUILD_MESSAGE_TIMESTAMP="$(echo '"'$BUILD_MESSAGE_TIMESTAMP'"')" PLAT=$plat SPD=opteed MBEDTLS_DIR=/$plat/mbedtls-mbedtls-$MTLS_VER TRUSTED_BOARD_BOOT=1 GENERATE_COT=1 ARM_ROTPK_LOCATION=devel_rsa ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem bl31
    ls -la build/$plat/release/bl31/
  popd
done
