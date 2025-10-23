#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
unzip -q $EDKP_VER.zip > /dev/null
pushd /edk2-$EDK_VER
  source edksetup.sh
  make -C BaseTools
  build -p \$ACTIVE_PLATFORM -b RELEASE -a AARCH64 -t GCC5 -n `nproc`
popd
