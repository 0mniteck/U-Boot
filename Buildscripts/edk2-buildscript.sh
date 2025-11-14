#!/usr/bin/env bash
env | sort
unzip -q $EDKP_VER.zip > /dev/null
pushd /edk2-$EDK_VER
  sed -i "19,20d;22,24d" BaseTools/Source/C/VfrCompile/GNUmakefile
  sed -i "179d;182,185d" BaseTools/Source/C/Makefiles/header.makefile
  source edksetup.sh
  make -C BaseTools
  build -p $ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
popd
