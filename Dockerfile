ARG HUB=0mniteck/debian
ARG BASE=default
ARG BASE_EXTRA=default

FROM $HUB:$BASE AS base

FROM $HUB-extra:$BASE_EXTRA AS optee
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ARG OPT_VER
ARG OPT_SUM
ENV OPT_VER=$OPT_VER
ENV OPT_SUM=$OPT_SUM
ADD https://github.com/OP-TEE/optee_os/archive/refs/tags/$OPT_VER.zip /
RUN echo "$OPT_SUM  $OPT_VER.zip" | sha512sum --status -c - && echo "OP-TEE Checksum Matched!" || exit 1
ARG ENTRYPOINT
COPY Buildscripts/$ENTRYPOINT-buildscript.sh /

FROM base AS arm-trusted
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ARG BUILD_MESSAGE_TIMESTAMP
ENV BUILD_MESSAGE_TIMESTAMP="$BUILD_MESSAGE_TIMESTAMP"
ARG ATF_VER
ARG ATF_SUM
ARG ARCHS
ENV ARCHS=$ARCHS
ENV ATF_VER=$ATF_VER
ENV ATF_SUM=$ATF_SUM
ADD https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/$ATF_VER.zip /
RUN echo "$ATF_SUM  v$ATF_VER.zip" | sha512sum --status -c - && echo "TF-A Checksum Matched!" || exit 1
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
ENV UB_SUM=$UB_SUM
ADD https://github.com/u-boot/u-boot/archive/refs/tags/v$UB_VER.zip /
RUN echo "$UB_SUM  v$UB_VER.zip" | sha512sum --status -c - && echo "U-Boot Checksum Matched!" || exit 1
ENV TEE=/Builds/rk3399/tee.bin
COPY Builds /Builds
COPY Includes /Includes
COPY Configs /Configs
ARG ENTRYPOINT
COPY Buildscripts/$ENTRYPOINT-buildscript.sh /
