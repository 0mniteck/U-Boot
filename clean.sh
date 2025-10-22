#!/bin/bash

if [ "$1" = "yes" ]; then
  pushd Builds/
    find . ! -type d -delete
    for dev in $LIST
    do
      for loc in $dev $dev-SB $dev-TPM-SB $dev-MU-SB
      do
        touch $loc/tmp
      done
    done
    for arch in $ARCHS
    do
      touch $arch/tmp
    done
  popd
  pushd Results/
    find . ! -type d -delete
    touch tmp
  popd
fi

if [ "$1" = "cleanup" ]; then
  pushd Builds/
    for dev in $LIST
    do
      for loc in $dev $dev-SB $dev-TPM-SB $dev-MU-SB
      do
        rm -f $loc/tmp
      done
    done
    for arch in $ARCHS
    do
      rm -f $arch/tmp
    done
  popd
  pushd Results/
    rm -f tmp
  popd
  rm -f status.build && rm -f sys.info && rm -f vars.env
fi
exit
