ARG HUB=0mniteck/debian
ARG BASE=default
ARG BASE_EXTRA=default

FROM $HUB:$BASE AS base

FROM base AS edk2
RUN apt install -y nasm python3-setuptools
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ARG EDKP_VER
ARG EDKP_SUM
ARG EDK_VER
ENV EDK_VER=$EDK_VER
ENV EDKP_VER=$EDKP_VER
ADD https://github.com/tianocore/edk2-platforms/archive/$EDKP_VER.zip /$EDKP_VER.zip
RUN echo "$EDKP_SUM  $EDKP_VER.zip" | sha512sum --status -c - && echo "EDK2 Platform Checksum Matched!" || exit 1
RUN git clone https://github.com/tianocore/edk2.git -b $EDK_VER edk2-$EDK_VER
RUN cd /edk2-$EDK_VER && git submodule init && git submodule update --init --recursive
ARG ENTRYPOINT
COPY Buildscripts/$ENTRYPOINT-buildscript.sh /

FROM $HUB-extra:$BASE_EXTRA AS optee
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ARG OPT_VER
ARG OPT_SUM
ARG OPT_SUM2
ARG TPM_SUM
ARG SSL_VER
ARG SSL_SUM
ARG CROSS_VER
ARG CROSS_SUM
ARG ROT_SUM
ARG ARCHS
ENV ARCHS=$ARCHS
ENV OPT_VER=$OPT_VER
ENV SSL_VER=$SSL_VER
ENV CROSS_VER=$CROSS_VER
RUN apt install clang cmake codespell gdb-multiarch gettext libclang-rt-dev libncurses-dev lld makeinfo python3-pycryptodome python3-pycodestyle -y
ADD https://github.com/OP-TEE/optee_os/archive/refs/tags/$OPT_VER.zip /$OPT_VER.zip
ADD https://github.com/OP-TEE/optee_ftpm/archive/refs/tags/$OPT_VER.zip /ftpm_$OPT_VER.zip
ADD https://github.com/microsoft/ms-tpm-20-ref/archive/refs/tags/v1.83r1.zip /TPM.zip
ADD https://github.com/openssl/openssl/archive/refs/tags/openssl-$SSL_VER.zip /SSL.zip
ADD https://github.com/crosstool-ng/crosstool-ng/archive/refs/tags/crosstool-ng-$CROSS_VER.zip /CROSS.zip
ADD https://github.com/ARM-software/arm-trusted-firmware/raw/refs/heads/master/plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem /
RUN echo "$OPT_SUM  $OPT_VER.zip" | sha512sum --status -c - && echo "OP-TEE Checksum Matched!" || exit 1
RUN echo "$OPT_SUM2  ftpm_$OPT_VER.zip" | sha512sum --status -c - && echo "OP-TEE fTPM Checksum Matched!" || exit 1
RUN echo "$TPM_SUM  TPM.zip" | sha512sum --status -c - && echo "TPM Checksum Matched!" || exit 1
RUN echo "$SSL_SUM  SSL.zip" | sha512sum --status -c - && echo "OpenSSL Checksum Matched!" || exit 1
RUN echo "$CROSS_SUM  CROSS.zip" | sha512sum --status -c - && echo "Crosstool-ng Checksum Matched!" || exit 1
RUN echo "$ROT_SUM  arm_rotprivk_rsa.pem" | sha512sum --status -c - && echo "ATF ROT Key Checksum Matched!" || exit 1
COPY Builds/rk3399/BL32_AP_MM.fd /BL32_AP_MM.fd
ARG ENTRYPOINT
COPY Buildscripts/$ENTRYPOINT-buildscript.sh /

FROM base AS arm-trusted
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ARG BUILD_MESSAGE_TIMESTAMP
ENV BUILD_MESSAGE_TIMESTAMP="$BUILD_MESSAGE_TIMESTAMP"
ARG ATF_VER
ARG ATF_SUM
ARG MTLS_VER
ARG MTLS_SUM
ARG ARCHS
ENV ARCHS=$ARCHS
ENV ATF_VER=$ATF_VER
ENV MTLS_VER=$MTLS_VER
ADD https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/$ATF_VER.zip /
ADD https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-$MTLS_VER.zip /
RUN echo "$ATF_SUM  $ATF_VER.zip" | sha512sum --status -c - && echo "TF-A Checksum Matched!" || exit 1
RUN echo "$MTLS_SUM  mbedtls-$MTLS_VER.zip" | sha512sum --status -c - && echo "MTLS Checksum Matched!" || exit 1
ARG ENTRYPOINT
COPY Buildscripts/$ENTRYPOINT-buildscript.sh /

FROM base AS u-boot
RUN apt install -y libgnutls28-dev lzop
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ENV SOURCE_DATE="@$SOURCE_DATE_EPOCH";
ENV FORCE_SOURCE_DATE=1;
ARG UB_VER
ARG UB_SUM
ENV UB_VER=$UB_VER
ADD https://github.com/u-boot/u-boot/archive/refs/tags/v$UB_VER.zip /
RUN echo "$UB_SUM  v$UB_VER.zip" | sha512sum --status -c - && echo "U-Boot Checksum Matched!" || exit 1
COPY Builds /Builds
COPY Includes /Includes
COPY Configs /Configs
ARG ENTRYPOINT
COPY Buildscripts/$ENTRYPOINT-buildscript.sh /
