#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  unzip -q $EDKP_VER.zip > /dev/null
    source edksetup.sh
    make -C BaseTools
    build -n `getconf _NPROCESSORS_ONLN` -p \$ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -D DO_X86EMU=TRUE -n `nproc`
  popd
done
