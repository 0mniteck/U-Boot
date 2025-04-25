#!/usr/bin/env bash
trap '[[ $pid ]] && kill $pid; exit' EXIT
for plat in $ARCHS
do
  echo "Unzipping TF-A for $plat..."
  unzip -q $ATF_VER.zip -d /$plat > /dev/null
  echo "Entering /$plat/arm-trusted-firmware-$ATF_VER"
  pushd /$plat/arm-trusted-firmware-$ATF_VER
    make realclean && make BUILD_MESSAGE_TIMESTAMP="$(echo '"'$BUILD_MESSAGE_TIMESTAMP'"')" PLAT=$plat bl31
    ls -la build/$plat/release/bl31/
  popd
done
