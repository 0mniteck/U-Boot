#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
unzip -q $EDKP_VER.zip > /dev/null
pushd /edk2-$EDK_VER
  # Remove if statements that are not nessasary assuming clang or gcc
  sed -i "19,20d;22,24d" BaseTools/Source/C/VfrCompile/GNUmakefile
  sed -i "76d;79d;82d" BaseTools/Source/C/Makefiles/header.makefile
  source edksetup.sh
  make -C BaseTools
  build -p $ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
popd
