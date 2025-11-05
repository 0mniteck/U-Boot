ARG HUB BASE BASE_EXTRA SOURCE_DATE_EPOCH ENTRYPOINT

FROM $HUB:$BASE AS base
ONBUILD RUN echo "Next stage starting:"; sleep 5

FROM $HUB-extra:$BASE_EXTRA AS base_extra
ONBUILD RUN echo "Next stage starting:"; sleep 5

FROM base AS edk2
ARG EDK_VER EDKP_VER EDKP_SUM
ENV EDK_VER=$EDK_VER EDKP_VER=$EDKP_VER SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/tianocore/edk2-platforms/archive/$EDKP_VER.zip /$EDKP_VER.zip
RUN apt install -y nasm
RUN echo "$EDKP_SUM  $EDKP_VER.zip" | sha512sum --status -c - && echo "EDK2 Platform Checksum Matched!" || exit 1; sleep 5
RUN git clone https://github.com/tianocore/edk2.git -b $EDK_VER edk2-$EDK_VER
RUN cd /edk2-$EDK_VER && git submodule init && git submodule update --init --recursive
ENTRYPOINT exec /$ENTRYPOINT-buildscript.sh

FROM base_extra AS optee
ARG OPT_VER OPT_SUM OPT_SUM2 TPM_SUM SSL_VER SSL_SUM CROSS_VER CROSS_SUM ROT_SUM ARCHS
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH OPT_VER=$OPT_VER SSL_VER=$SSL_VER CROSS_VER=$CROSS_VER ARCHS="$ARCHS"
COPY --link Builds/rk3399/BL32_AP_MM.fd /BL32_AP_MM.fd
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/OP-TEE/optee_os/archive/refs/tags/$OPT_VER.zip /$OPT_VER.zip
ADD --link https://github.com/OP-TEE/optee_ftpm/archive/refs/tags/$OPT_VER.zip /ftpm_$OPT_VER.zip
ADD --link https://github.com/microsoft/ms-tpm-20-ref/archive/refs/tags/v1.83r1.zip /TPM.zip
ADD --link https://github.com/openssl/openssl/archive/refs/tags/openssl-$SSL_VER.zip /SSL.zip
ADD --link https://github.com/crosstool-ng/crosstool-ng/archive/refs/tags/crosstool-ng-$CROSS_VER.zip /CROSS.zip
ADD --link https://github.com/ARM-software/arm-trusted-firmware/raw/refs/heads/master/plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem /
RUN apt install -y clang cmake codespell gdb-multiarch gettext help2man libclang-rt-dev \
libncurses-dev lld python3-pycryptodome python3-pycodestyle texinfo
RUN echo "$OPT_SUM  $OPT_VER.zip" | sha512sum --status -c - && echo "OP-TEE Checksum Matched!" || exit 1; sleep 5
RUN echo "$OPT_SUM2  ftpm_$OPT_VER.zip" | sha512sum --status -c - && echo "OP-TEE fTPM Checksum Matched!" || exit 1; sleep 5
RUN echo "$TPM_SUM  TPM.zip" | sha512sum --status -c - && echo "TPM Checksum Matched!" || exit 1; sleep 5
RUN echo "$SSL_SUM  SSL.zip" | sha512sum --status -c - && echo "OpenSSL Checksum Matched!" || exit 1; sleep 5
RUN echo "$CROSS_SUM  CROSS.zip" | sha512sum --status -c - && echo "Crosstool-ng Checksum Matched!" || exit 1; sleep 5
RUN echo "$ROT_SUM  arm_rotprivk_rsa.pem" | sha512sum --status -c - && echo "ATF ROT Key Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT exec /$ENTRYPOINT-buildscript.sh

FROM base AS arm-trusted
ARG BUILD_MESSAGE_TIMESTAMP ATF_VER ATF_SUM MTLS_VER MTLS_SUM ARCHS
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH BUILD_MESSAGE_TIMESTAMP="$BUILD_MESSAGE_TIMESTAMP" ATF_VER=$ATF_VER MTLS_VER=$MTLS_VER ARCHS="$ARCHS"
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/$ATF_VER.zip /
ADD --link https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-$MTLS_VER.zip /
RUN echo "$ATF_SUM  $ATF_VER.zip" | sha512sum --status -c - && echo "TF-A Checksum Matched!" || exit 1; sleep 5
RUN echo "$MTLS_SUM  mbedtls-$MTLS_VER.zip" | sha512sum --status -c - && echo "MTLS Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT exec /$ENTRYPOINT-buildscript.sh

FROM base AS u-boot
ARG UB_VER UB_SUM
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH SOURCE_DATE="@$SOURCE_DATE_EPOCH" FORCE_SOURCE_DATE=1 UB_VER=$UB_VER
COPY --link Builds /Builds
COPY --link Includes /Includes
COPY --link Configs /Configs
COPY --link Buildscripts/$ENTRYPOINT-buildscript.sh /
ADD --link https://github.com/u-boot/u-boot/archive/refs/tags/v$UB_VER.zip /
RUN apt install -y libgnutls28-dev lzop
RUN echo "$UB_SUM  v$UB_VER.zip" | sha512sum --status -c - && echo "U-Boot Checksum Matched!" || exit 1; sleep 5
ENTRYPOINT exec /$ENTRYPOINT-buildscript.sh
