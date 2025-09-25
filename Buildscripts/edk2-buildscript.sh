#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  unzip -q $EDK_VER.zip -d /$plat > /dev/null
  unzip -q $EDKP_VER.zip -d /$plat > /dev/null
  pushd /$plat/
    export WORKSPACE=/root
    export PACKAGES_PATH=/$plat/edk2-$(echo $EDK_VER):/$plat/edk2-platforms-$(echo $EDKP_VER)
    export ACTIVE_PLATFORM='Platform/StandaloneMm/PlatformStandaloneMmPkg/PlatformStandaloneMmRpmb.dsc'
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    source edksetup.sh
    make -C BaseTools
    build -n `getconf _NPROCESSORS_ONLN` -p \$ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -D DO_X86EMU=TRUE -n `nproc`
  popd
done
