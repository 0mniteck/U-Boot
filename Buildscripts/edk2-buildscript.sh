#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  unzip -q $EDK_VER.zip -d /$plat > /dev/null
  unzip -q $EDKP_VER.zip -d /$plat > /dev/null
  pushd /$plat/
  
  popd
done
