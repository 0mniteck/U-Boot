#!/usr/bin/env bash
env | sort
unzip -q SSL.zip -d / > /dev/null
mv /openssl-openssl-$SSL_VER /SSL
pushd /SSL
  sed -i "1,15d" build.info
  sed -i "s'MAJOR=.'MAJOR=1'" VERSION.dat
  sed -i "s'MINOR=.'MINOR=1'" VERSION.dat
  sed -i "s'PATCH=.'PATCH=0'" VERSION.dat
  ./Configure --api=1.1.0 linux-aarch64
  make
  cp include/crypto/sm4.h include/openssl/sm4.h
popd
