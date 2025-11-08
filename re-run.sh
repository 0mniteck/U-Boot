#!/bin/bash
source ../defaults 2>/dev/null
source ./*.set 2>/dev/null && rm -f *.set
source ./.set 2>/dev/null && rm -f .set
env
mv build.info tmp && echo "Starting Build: $(date -u '+on %D at %R UTC')" > build.info && cat tmp >> build.info && rm -f tmp
echo "Starting Build: $(date -u '+on %D at %R UTC')"
ARCHS=$(echo $ARCHS | tr ' ' '\n' | sort -u | tr '\n' ' ')
TARGETS=$(echo $TARGETS | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ "$TARGETS" != "" ]; then
  echo "TARGET: $TARGETS"
  export TARGET="$TARGETS"
fi
if [ "$CHECK" = "yes" ]; then
  echo "CHECK REPRODUCIBILITY: $6"
  export check_file=1
fi
if [ "$MOUNT" != "" ]; then
  echo "MOUNT: /dev/$MOUNT"
  export mount="$MOUNT"
  export unmount="unmount"
fi
if [ "$CR_C" = "yes" ]; then
  echo "CROSS_COMPILE: $CR_C"
  export CROSS="--platform linux/arm64"
  export cross="cross"
fi
if [ "$DEV" = "yes" ]; then
  echo "DEV_BUILD: $DEV"
  CACHE="--cache-to type=local,dest=.git/Cache,mode=max --cache-from type=local,src=.git/Cache"
  load() { # $1 = Name
    export LOAD="--load $CROSS $CACHE --target $1 --tag $1"
    export NAME=$1
    return
  }
else
  export BUILDX_METADATA_PROVENANCE=max
  export install="install"
  export signing=1
  load() { # $1 Name
    export LOAD="--load $CROSS --target $1 --tag $1 --metadata-file Results/$1/$1.meta.json"
    export NAME=$1
    return
  }
fi
if [ "$CLEAN" = "yes" ]; then
  echo "CLEAN_BUILD: $CLEAN"
  export remove="remove"
else
  echo "CLEAN_BUILD: $CLEAN"
fi
if [ "$EPOCH" != "" ]; then
  echo "SOURCE_DATE_EPOCH: $EPOCH"
  export source_date_epoch=$EPOCH
  source_date="@$source_date_epoch"
  echo "SOURCE_DATE: $source_date"
  build_message_timestamp="$(date +'%b %d %Y - 00:00:00 +0000' -d $source_date)";
  echo "BUILD_MESSAGE_TIMESTAMP: $build_message_timestamp"
fi

stop() { # $1 = Name
  docker stop $1 > /dev/null && echo "$1 stopped" && docker rm --volumes $1 > /dev/null && echo "$1 removed"
}

scan_using_grype() { # $1 = Name, $2 = Type:[Name]
  if [ "$DEV" != "yes" ]; then
    pushd Results/$1
      mkdir -p "~/.cache/syft" && TMPDIR="~/.cache/syft" syft scan $2 -o spdx-json=$1.spdx.json
      script -q -c "grype $GRCONF sbom:$1.spdx.json -o json > $1.grype.json" $1.grype.tmp.tmp > $1.grype.tmp
      marker() { # $1 = Name, $2 = Order, $3 = Marker/ID
        grep "$3" $1.grype.tmp | tail -n 1 > $1.grype.status.$2
        tr -d '\000-\037\177' < $1.grype.status.$2 | sed '/^$/d' > $1.grype.status.$2.tmp
        line1=$(<"${1}.grype.status.${2}.tmp")
        left1="${line1%%' [K[2A'*}"
        right1="${line1#*' [K[2A'}"
        if [[ "$right1" == *$3* ]]; then
          export "wright$2"="${right1%%' [K'*}"
        elif [[ "$left1" == *$3* ]]; then
          export "wright$2"="${left1%%' [K'*}"
        fi
      }
      marker $1 1 "✔ Scanned for vulnerabilities"
      marker $1 2 "├── by severity:"
      marker $1 3 "└── by status:"
      echo $wright1 > $1.grype.status
      echo $wright2 >> $1.grype.status
      echo $wright3 >> $1.grype.status
      sed -i "s'\[K''" $1.grype.status
      sed -i "s'\[2A''" $1.grype.status
      rm -f $1.grype.tmp*
      rm -f $1.grype.status.*
      cat $1.grype.status
    popd
  else
    return
  fi
}

pushd ..
  $PWD/install.sh run.install "$install" "$remove" "$(whoami)" "$cross" "$mount"
  
  docker buildx create --name U-Boot-Builder $CROSS --driver-opt "network=host" --bootstrap --use
  if [ "$cross" = "cross" ]; then
    docker run --privileged --rm tonistiigi/binfmt:qemu-v10.0.4-56 --install all
  fi
  
  load base
  if [[ "$TARGET" == *$NAME* ]]; then
    docker buildx build $LOAD \
      --build-arg HUB=$HUB \
      --build-arg BASE=$BASE \
      -f Dockerfile .
  fi
  
  load base_extra
  if [[ "$TARGET" == *$NAME* ]]; then
    docker buildx build $LOAD \
      --build-arg HUB=$HUB \
      --build-arg BASE=$BASE \
      --build-arg BASE_EXTRA=$BASE_EXTRA \
      -f Dockerfile .
  fi
  
  load edk2
  if [[ "$TARGET" == *$NAME* ]]; then
    docker buildx build $LOAD \
      --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
      --build-arg EDKP_VER=$EDKP_VER \
      --build-arg EDKP_SUM=$EDKP_SUM \
      --build-arg EDK_VER=$EDK_VER \
      --build-arg HUB=$HUB \
      --build-arg BASE=$BASE \
      --build-arg ENTRYPOINT=$NAME \
      -f Dockerfile .
  
    scan_using_grype $NAME docker:$NAME
  
    docker run -it --cpus=$(nproc) \
      --name $NAME $CROSS \
      --user "$(id -u):$(id -g)" \
      -e SOURCE_DATE_EPOCH=$source_date_epoch \
      -e EDKP_VER=$EDKP_VER \
      -e EDK_VER=$EDK_VER \
      -e WORKSPACE=/ \
      -e PACKAGES_PATH="/edk2-$(echo $EDK_VER):/edk2-platforms-$(echo $EDKP_VER)" \
      -e ACTIVE_PLATFORM="Platform/StandaloneMm/PlatformStandaloneMmPkg/PlatformStandaloneMmRpmb.dsc" \
      -e GCC5_AARCH64_PREFIX="aarch64-linux-gnu-" \
      $NAME
  
    docker cp $NAME:/Build/MmStandaloneRpmb/RELEASE_GCC5/FV/BL32_AP_MM.fd Builds/rk3399/BL32_AP_MM.fd
    sha512sum Builds/rk3399/BL32_AP_MM.fd && sha512sum Builds/rk3399/BL32_AP_MM.fd >> Results/release.sha512sum
    openssl dgst -SHA3-256 Builds/rk3399/BL32_AP_MM.fd && openssl dgst -SHA3-256 Builds/rk3399/BL32_AP_MM.fd >> Results/release.sha3sum
    stop $NAME
  fi
  
  load optee
  if [[ "$TARGET" == *$NAME* ]]; then
    docker buildx build $LOAD \
      --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
      --build-arg OPT_VER=$OPT_VER \
      --build-arg OPT_SUM=$OPT_SUM \
      --build-arg OPT_SUM2=$OPT_SUM2 \
      --build-arg TPM_SUM=$TPM_SUM \
      --build-arg SSL_VER=$SSL_VER \
      --build-arg SSL_SUM=$SSL_SUM \
      --build-arg CROSS_VER=$CROSS_VER \
      --build-arg CROSS_SUM=$CROSS_SUM \
      --build-arg ROT_SUM=$ROT_SUM \
      --build-arg HUB=$HUB \
      --build-arg BASE=$BASE \
      --build-arg BASE_EXTRA=$BASE_EXTRA \
      --build-arg ENTRYPOINT=$NAME \
      -f Dockerfile .
    
    scan_using_grype $NAME docker:$NAME
    
    docker run -it --cpus=$(nproc) \
      --name $NAME $CROSS \
      --user "$(id -u):$(id -g)" \
      -e SOURCE_DATE_EPOCH=$source_date_epoch \
      -e OPT_VER=$OPT_VER \
      -e SSL_VER=$SSL_VER \
      -e CROSS_VER=$CROSS_VER \
      -e ARCHS="$ARCHS" \
      $NAME
    
    for arch in $ARCHS
    do
      for tpm in ":-tpm" "/NOTPM:"
      do
        tpm=$(echo $tpm | cut -d':' -f2)
        docker cp $NAME:$(echo $tpm | cut -d':' -f1)/$arch/optee_os-$OPT_VER/out/arm-plat-rockchip/core/tee.bin Builds/$arch/tee$tpm.bin
        sha512sum Builds/$arch/tee$tpm.bin && sha512sum Builds/$arch/tee$tpm.bin >> Results/release.sha512sum
        openssl dgst -SHA3-256 Builds/$arch/tee$tpm.bin && openssl dgst -SHA3-256 Builds/$arch/tee$tpm.bin >> Results/release.sha3sum
      done
    done
    stop $NAME
  fi
  
  load arm-trusted
  if [[ "$TARGET" == *$NAME* ]]; then
    docker buildx build $LOAD \
      --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
      --build-arg BUILD_MESSAGE_TIMESTAMP="$build_message_timestamp" \
      --build-arg ATF_VER=$ATF_VER \
      --build-arg ATF_SUM=$ATF_SUM \
      --build-arg MTLS_VER=$MTLS_VER \
      --build-arg MTLS_SUM=$MTLS_SUM \
      --build-arg HUB=$HUB \
      --build-arg BASE=$BASE \
      --build-arg ENTRYPOINT=$NAME \
      -f Dockerfile .
    
    scan_using_grype $NAME docker:$NAME
    
    docker run -it --cpus=$(nproc) \
      --name $NAME $CROSS \
      --user "$(id -u):$(id -g)" \
      -e SOURCE_DATE_EPOCH=$source_date_epoch \
      -e BUILD_MESSAGE_TIMESTAMP="$build_message_timestamp" \
      -e ATF_VER=$ATF_VER \
      -e ARCHS="$ARCHS" \
      $NAME
    
    for arch in $ARCHS
    do
      docker cp $NAME:/$arch/arm-trusted-firmware-$ATF_VER/build/$arch/release/bl31/bl31.elf Builds/$arch/
      sha512sum Builds/$arch/bl31.elf && sha512sum Builds/$arch/bl31.elf >> Results/release.sha512sum
      openssl dgst -SHA3-256 Builds/$arch/bl31.elf && openssl dgst -SHA3-256 Builds/$arch/bl31.elf >> Results/release.sha3sum
    done
    stop $NAME
  fi
  
  load u-boot
  if [[ "$TARGET" == *$NAME* ]]; then
    docker buildx build $LOAD \
      --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
      --build-arg UB_VER=$UB_VER \
      --build-arg UB_SUM=$UB_SUM \
      --build-arg HUB=$HUB \
      --build-arg BASE=$BASE \
      --build-arg ENTRYPOINT=$NAME \
      -f Dockerfile .
    
    scan_using_grype $NAME docker:$NAME
    
    docker run -it --cpus=$(nproc) \
      --name $NAME $CROSS \
      --user "$(id -u):$(id -g)" \
      -e SOURCE_DATE_EPOCH=$source_date_epoch \
      -e SOURCE_DATE=$source_date \
      -e UB_VER=$UB_VER \
      -e BUILD_LIST="$BUILD_LIST" \
      -e DEV_BUILD=$DEV \
      $NAME
    
    for dev in $LIST
    do
      for loc in $VARIANTS
      do
        docker cp $NAME:/$dev$loc/ Builds
        sha512sum Builds/$dev$loc/u-boot-rockchip.bin && sha512sum Builds/$dev$loc/u-boot-rockchip.bin >> Results/release.sha512sum
        openssl dgst -SHA3-256 Builds/$dev$loc/u-boot-rockchip.bin && openssl dgst -SHA3-256 Builds/$dev$loc/u-boot-rockchip.bin >> Results/release.sha3sum
        sha512sum Builds/$dev$loc/u-boot-rockchip-spi.bin && sha512sum Builds/$dev$loc/u-boot-rockchip-spi.bin >> Results/release.sha512sum
        openssl dgst -SHA3-256 Builds/$dev$loc/u-boot-rockchip-spi.bin && openssl dgst -SHA3-256 Builds/$dev$loc/u-boot-rockchip-spi.bin >> Results/release.sha3sum
      done
      docker cp $NAME:/$dev/ Builds
      sha512sum Builds/$dev/u-boot-rockchip.bin && sha512sum Builds/$dev/u-boot-rockchip.bin >> Results/release.sha512sum
      openssl dgst -SHA3-256 Builds/$dev/u-boot-rockchip.bin && openssl dgst -SHA3-256 Builds/$dev/u-boot-rockchip.bin >> Results/release.sha3sum
      sha512sum Builds/$dev/u-boot-rockchip-spi.bin && sha512sum Builds/$dev/u-boot-rockchip-spi.bin >> Results/release.sha512sum
      openssl dgst -SHA3-256 Builds/$dev/u-boot-rockchip-spi.bin && openssl dgst -SHA3-256 Builds/$dev/u-boot-rockchip-spi.bin >> Results/release.sha3sum
    done
    docker cp $NAME:/sys.info Results/sys.info
    stop $NAME
  fi
  
  load ubuntu
  if [[ "$TARGET" == *$NAME* ]]; then
    scan_using_grype ubuntu "/ --select-catalogers debian"
  fi

  $PWD/install.sh run.uninstall "$remove" "$unmount"

  load u-boot
  if [[ "$TARGET" == *$NAME* ]]; then
    if [ "$DEV" != "yes" ]; then
      mkfs.fat -i 00000000 -n "U-BOOT" --invariant -C /tmp/sdcard.img 35000
      for dev in $LIST
      do
        for loc in $VARIANTS
        do
          pushd Builds/$dev$loc/
            echo "dc3272192cb9339d79bc1b8d6066ba056e2d7f952313688085f8009d221f692842f6cd0f378bd83c22dfcd2b5b266e8b0c6805ae5c9a05b4ffe0edefe7b4d079  /tmp/sdcard.img" | sha512sum -c - && wait || exit 1
            cp /tmp/sdcard.img sdcard.img && mount sdcard.img /mnt
            cp u-boot-rockchip.bin /mnt/u-boot-rockchip.bin
            cp u-boot-rockchip-spi.bin /mnt/u-boot-rockchip-spi.bin
            touch -d "$(date -R -d $source_date)" /mnt/*
            touch -d "$(date -R -d $source_date)" /mnt
            touch -c -d "$(date -R -d $source_date)" /mnt/*
            touch -c -d "$(date -R -d $source_date)" /mnt
            touch -a -d "$(date -R -d $source_date)" /mnt/*
            touch -a -d "$(date -R -d $source_date)" /mnt
            dd if=/mnt/u-boot-rockchip.bin of=sdcard.img seek=64 conv=notrunc status=progress
            sync && umount /mnt
          popd
          sha512sum Builds/$dev$loc/sdcard.img >> Results/release.sha512sum
        done
      done
      rm -f /tmp/sdcard.img
    fi
  fi
popd
echo "0mniteck's Current GPG Key ID: 287EE837E6ED2DD3" >> build.info
echo "Base Build System: $(uname -o) $(uname -r) $(uname -m) $(lsb_release -ds) $(lsb_release -cs) $(uname -v)" >> build.info && cat sys.info >> build.info
echo "Build Complete: $(date -u '+on %D at %R UTC')" >> build.info && echo "Build Complete: $(date -u '+on %D at %R UTC')"
if [ "$check_file" = "1" ]; then
  cp /tmp/release.last.sha512sum release.last.sha512sum && cp /tmp/release.last.sha3sum release.last.sha3sum
  sha512sum -c release.last.sha512sum && REP="ly Reproduced" || wait
fi
echo "Successful$REP Build of U-Boot v$UB_VER on $build_message_timestamp W/ TF-A $ATF_VER & OP-TEE v$OPT_VER" > status.info
