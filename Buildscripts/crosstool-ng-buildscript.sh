#!/usr/bin/env bash
env | sort >> /.env && echo "" >> /.env
unzip -q CROSS.zip -d / > /dev/null
mv /crosstool-ng-crosstool-ng-$CROSS_VER /CROSS
printf '\n\n\n\n\ny\n' | adduser --disabled-password --no-create-home cross && echo "USER CROSS ADDED"
chown -R cross:cross /CROSS
chmod -R 755 $_
mkdir -p /home/cross/src
chown -R cross:cross /home/cross
chmod -R 755 $_
pushd /CROSS
su cross -c "
  echo \$(whoami)
  ./bootstrap
  ./configure --enable-local
  make
  ./ct-ng aarch64-unknown-linux-gnu
  cat >> .config << __EOF
CT_CC_GCC_EXTRA_CONFIG_ARRAY='--enable-standard-branch-protection'
CT_CC_GCC_CORE_EXTRA_CONFIG_ARRAY='--enable-standard-branch-protection'
__EOF
  ./ct-ng build.$(nproc)
  ls -la /home/cross/x-tools/aarch64-unknown-linux-gnu/
  ls -la /home/cross/x-tools/aarch64-unknown-linux-gnu/bin"
popd
