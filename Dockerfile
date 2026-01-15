ARG HUB=0mniteck/debian BASE=latest BASE_EXTRA=latest SOURCE_DATE_EPOCH ENTRYPOINT
FROM $HUB:$BASE AS base
ARG HUB BASE ENTRYPOINT
ONBUILD RUN echo "U-Boot-Builder for $ENTRYPOINT starting: Using base image $HUB $BASE"; sleep 5
FROM $HUB-extra:$BASE_EXTRA AS base_extra
ARG HUB BASE_EXTRA ENTRYPOINT
ONBUILD RUN echo "U-Boot-Builder for $ENTRYPOINT starting: Using base image $HUB-extra $BASE_EXTRA"; sleep 5

FROM base_extra AS crosstool-ng
ARG SOURCE_DATE_EPOCH CROSS_VER CROSS_SUM ENTRYPOINT
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH CROSS_VER=$CROSS_VER ENTRYPOINT=$ENTRYPOINT
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/crosstool-ng/crosstool-ng/archive/refs/tags/crosstool-ng-$CROSS_VER.zip /CROSS.zip
RUN echo "$CROSS_SUM  CROSS.zip" | sha512sum --status -c - && echo "Crosstool-ng Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT ["sh","-c","/$ENTRYPOINT-buildscript.sh"]

FROM base AS edk2
ARG SOURCE_DATE_EPOCH EDK_VER EDKP_VER EDKP_SUM ENTRYPOINT
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH EDK_VER=$EDK_VER EDKP_VER=$EDKP_VER ENTRYPOINT=$ENTRYPOINT
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/tianocore/edk2-platforms/archive/$EDKP_VER.zip /$EDKP_VER.zip
ADD --link --keep-git-dir=true https://github.com/tianocore/edk2.git?tag=$EDK_VER&checksum=d46aa46 /edk2-$EDK_VER
RUN echo "$EDKP_SUM  $EDKP_VER.zip" | sha512sum --status -c - && echo "EDK2 Platform Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT ["sh","-c","/$ENTRYPOINT-buildscript.sh"]

FROM base AS openssl
ARG SOURCE_DATE_EPOCH SSL_VER SSL_SUM ENTRYPOINT
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH SSL_VER=$SSL_VER ENTRYPOINT=$ENTRYPOINT
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/openssl/openssl/archive/refs/tags/openssl-$SSL_VER.zip /SSL.zip
RUN echo "$SSL_SUM  SSL.zip" | sha512sum --status -c - && echo "OpenSSL Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT ["sh","-c","/$ENTRYPOINT-buildscript.sh"]

FROM base_extra AS optee
ARG SOURCE_DATE_EPOCH OPT_VER OPT_SUM OPT_SUM2 TPM_SUM ROT_SUM ENTRYPOINT
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH OPT_VER=$OPT_VER ENTRYPOINT=$ENTRYPOINT
COPY --link Builds/rk3399/openssl/* /SSL/
COPY --link Builds/rk3399/aarch64-* /CROSS/
COPY --link Builds/rk3399/BL32_AP_MM.fd Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/OP-TEE/optee_os/archive/refs/tags/$OPT_VER.zip /OPTEE.zip
ADD --link https://github.com/OP-TEE/optee_ftpm/archive/refs/tags/$OPT_VER.zip /ftpm_OPTEE.zip
ADD --link https://github.com/microsoft/ms-tpm-20-ref/archive/refs/tags/v1.83r1.zip /TPM.zip
ADD --link https://github.com/ARM-software/arm-trusted-firmware/raw/refs/heads/master/plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem /
RUN echo "$OPT_SUM  OPTEE.zip" | sha512sum --status -c - && echo "OP-TEE Checksum Matched!" || exit 1; sleep 5
RUN echo "$OPT_SUM2  ftpm_OPTEE.zip" | sha512sum --status -c - && echo "OP-TEE fTPM Checksum Matched!" || exit 1; sleep 5
RUN echo "$TPM_SUM  TPM.zip" | sha512sum --status -c - && echo "TPM Checksum Matched!" || exit 1; sleep 5
RUN echo "$ROT_SUM  arm_rotprivk_rsa.pem" | sha512sum --status -c - && echo "ATF ROT Key Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT ["sh","-c","/$ENTRYPOINT-buildscript.sh"]

FROM base AS arm-trusted
ARG SOURCE_DATE_EPOCH BUILD_MESSAGE_TIMESTAMP ATF_VER ATF_SUM MTLS_VER MTLS_SUM ENTRYPOINT
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH BUILD_MESSAGE_TIMESTAMP="$BUILD_MESSAGE_TIMESTAMP" ATF_VER=$ATF_VER MTLS_VER=$MTLS_VER ENTRYPOINT=$ENTRYPOINT
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/$ATF_VER.zip /
ADD --link https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-$MTLS_VER.zip /
RUN echo "$ATF_SUM  $ATF_VER.zip" | sha512sum --status -c - && echo "TF-A Checksum Matched!" || exit 1; sleep 5
RUN echo "$MTLS_SUM  mbedtls-$MTLS_VER.zip" | sha512sum --status -c - && echo "MTLS Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT ["sh","-c","/$ENTRYPOINT-buildscript.sh"]

FROM base AS u-boot
ARG SOURCE_DATE_EPOCH UB_VER UB_SUM ENTRYPOINT
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH SOURCE_DATE="@$SOURCE_DATE_EPOCH" FORCE_SOURCE_DATE=1 UB_VER=$UB_VER ENTRYPOINT=$ENTRYPOINT
COPY --link Builds/ Includes/ Configs/ Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/u-boot/u-boot/archive/refs/tags/v$UB_VER.zip /
RUN echo "$UB_SUM  v$UB_VER.zip" | sha512sum --status -c - && echo "U-Boot Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT ["sh","-c","/$ENTRYPOINT-buildscript.sh"]
