#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
unzip -q $EDKP_VER.zip > /dev/null
pushd /edk2-$EDK_VER
  sed -i "s'Pccts/antlr/antlr -CC -e3 -ck 3 -k 2'Pccts/antlr/antlr -CC -e3 -ck 3 -k 3'" BaseTools/Source/C/VfrCompile/GNUmakefile
  cat BaseTools/Source/C/VfrCompile/GNUmakefile
  source edksetup.sh
  make -C BaseTools
  build -p $ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
popd
