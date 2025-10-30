#!/bin/bash

source_date_epoch=1;
if [ "$1" = "today" ]; then
  timestamp=$(date -d $(date +%D) +%s);
  if [ "${timestamp}" != "" ]; then
    echo "Setting SOURCE_DATE_EPOCH from today's date: $(date +%D) = @$timestamp";
    source_date_epoch=$((timestamp));
  else
    echo "Can't get timestamp. Defaulting to 1.";
    source_date_epoch=1;
  fi
elif [ "$1" != 0 ]; then
  echo "Using override timestamp for SOURCE_DATE_EPOCH."
  source_date_epoch=$(($1))
else
  timestamp=$(cat /tmp/release.last.sha512sum | grep Epoch | cut -d ' ' -f5)
  if [ "${timestamp}" != "" ]; then
    echo "Setting SOURCE_DATE_EPOCH from release.sha512sum: $(cat /tmp/release.last.sha512sum | grep Epoch | cut -d ' ' -f5)"
    source_date_epoch=$((timestamp))
    check_file=1
  else
    echo "Can't get latest commit timestamp. Defaulting to 1."
    source_date_epoch=1
  fi
fi

source_date="@$source_date_epoch"
build_message_timestamp="$(date +'%b %d %Y - 00:00:00 +0000' -d $source_date)";
local_cache="--cache-to type=local,dest=.git/Cache,mode=max --cache-from type=local,src=.git/Cache"

if [ "$5" != "" ]; then
  echo "MOUNT: /dev/$5"
  export MOUNT="/dev/$5"
fi
if [ "$4" = "yes" ]; then
  echo "CROSS_COMPILE: $4"
  export CROSS="--platform linux/arm64"
fi
if [ "$2" = "no" ]; then
  echo "CLEAN_BUILD: $2"
fi
if [ "$3" = "yes" ]; then
  echo "DEV_BUILD: $3"
  load() { # $1 = Name
    export LOAD="--load $CROSS $local_cache --target $1 --tag $1"
    export NAME=$1
    return
    }
else
  load() { # $1 Name
    export LOAD="--load $CROSS --target $1 --tag $1 --metadata-file Results/$1/$1.meta.json"
    export BUILDX_METADATA_PROVENANCE=max
    export SIGNING=1
    export NAME=$1
    return
    }
fi

echo "SOURCE_DATE: $source_date"
echo "SOURCE_DATE_EPOCH: $source_date_epoch"
echo "BUILD_MESSAGE_TIMESTAMP: $build_message_timestamp"
ARCHS=$(echo $ARCHS | tr ' ' '\n' | sort -u | tr '\n' ' ')
echo "# Starting Build: $(date -u '+on %D at %R UTC')" >> Results/release.sha512sum && echo "" >> Results/release.sha512sum && echo "Starting Build: $(date -u '+on %D at %R UTC')"
echo '' > Results/release.sha512sum && echo '' > Results/release.sha3sum

if [ "$3" != "yes" ]; then
  snap refresh
  snap install syft --classic
  snap install grype --classic
fi
./clean.sh cleanup.snaps
./clean.sh cleanup.docker $5
if [ "$5" != "" ]; then
  systemd-cryptsetup attach Luks-Signal /dev/$5
fi
mkdir -p /var/snap/docker
if [ "$5" != "" ]; then
  mount /dev/mapper/Luks-Signal /var/snap/docker
  rm -f -r /var/snap/docker/*
fi
chown root:root /var/snap/docker
if [ "$4" = "yes" ]; then
  snap install docker --revision=3377
else
  snap install docker --revision=3380 && systemctl stop snap.docker.nvidia-container-toolkit
  systemctl disable snap.docker.nvidia-container-toolkit
fi

stop() { # $1 = Name
  docker stop $1 > /dev/null && echo "$1 stopped" && docker rm --volumes $1 > /dev/null && echo "$1 removed"
}

scan_using_grype() { # $1 = Name, $2 = Type:[Name], $3 = $3
  if [ "$3" != "yes" ]; then
    pushd Results/$1
      if [ -f "$HOME/.grype.yaml" ]; then GRCONF="-c $HOME/.grype.yaml"; fi
      mkdir -p "$HOME/syft" && TMPDIR="$HOME/syft" syft scan $2 -o spdx-json=$1.spdx.json
      script -q -c "grype $GRCONF sbom:$1.spdx.json -o json > $1.grype.json" $1.grype.tmp
      grep "✔ Scanned for vulnerabilities" $1.grype.tmp | tail -n 1 > $1.grype.status.1
      tr -d '\000-\037\177' < $1.grype.status.1 | sed '/^$/d' > $1.grype.status.1.tmp
      line1=$(cat $1.grype.status.1.tmp)
      left1=${line1%%" [K"*}
      grep "├── by severity:" $1.grype.tmp | tail -n 1 > $1.grype.status.2
      tr -d '\000-\037\177' < $1.grype.status.2 | sed '/^$/d' > $1.grype.status.2.tmp
      line2=$(cat $1.grype.status.2.tmp)
      left2=${line2%%" [K"*}
      grep "└── by status:" $1.grype.tmp | tail -n 1 > $1.grype.status.3
      tr -d '\000-\037\177' < $1.grype.status.3 | sed '/^$/d' > $1.grype.status.3.tmp
      line3=$(cat $1.grype.status.3.tmp)
      left3=${line3%%" [K"*}
      echo $left1 > $1.grype.status
      echo $left2 >> $1.grype.status
      echo $left3 >> $1.grype.status
      rm -f $1.grype.tmp
      rm -f $1.grype.status.*
      cat $1.grype.status
    popd
  else
    return
  fi
}

docker buildx create --name U-Boot-Builder $CROSS --driver-opt "network=host" --bootstrap --use
if [ "$4" = "yes" ]; then
  docker run --privileged --rm tonistiigi/binfmt:qemu-v10.0.4-56 --install all
fi

# load base
# docker buildx build $LOAD \
#   --build-arg HUB=$HUB \
#   --build-arg BASE=$BASE \
#   -f Dockerfile .
  
if [ "$2" = "yes" ]; then
  load edk2
  docker buildx build $LOAD \
    --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
    --build-arg EDKP_VER=$EDKP_VER \
    --build-arg EDKP_SUM=$EDKP_SUM \
    --build-arg EDK_VER=$EDK_VER \
    --build-arg HUB=$HUB \
    --build-arg BASE=$BASE \
    --build-arg BASE_EXTRA=$BASE_EXTRA \
    --build-arg ENTRYPOINT=$NAME \
    -f Dockerfile .

  scan_using_grype $NAME docker:$NAME $3

  docker run -it --cpus=$(nproc) \
    --name $NAME $CROSS \
    --user "$(id -u):$(id -g)" \
    --entrypoint /$NAME-buildscript.sh \
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
docker buildx build $LOAD \
  --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
  --build-arg OPT_VER=$OPT_VER \
  --build-arg OPT_SUM=$OPT_SUM \
  --build-arg OPT_SUM2=$OPT_SUM2 \
  --build-arg TPM_SUM=$TPM_SUM \
  --build-arg SSL_VER=$SSL_VER \
  --build-arg SSL_SUM=$SSL_SUM \
  --build-arg ROT_SUM=$ROT_SUM \
  --build-arg HUB=$HUB \
  --build-arg BASE=$BASE \
  --build-arg BASE_EXTRA=$BASE_EXTRA \
  --build-arg ENTRYPOINT=$NAME \
  -f Dockerfile .

scan_using_grype $NAME docker:$NAME $3

docker run -it --cpus=$(nproc) \
  --name $NAME $CROSS \
  --user "$(id -u):$(id -g)" \
  --entrypoint /$NAME-buildscript.sh \
  -e SOURCE_DATE_EPOCH=$source_date_epoch \
  -e SSL_VER=$SSL_VER \
  -e OPT_VER=$OPT_VER \
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

load arm-trusted
docker buildx build $LOAD \
  --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
  --build-arg BUILD_MESSAGE_TIMESTAMP="$build_message_timestamp" \
  --build-arg ATF_VER=$ATF_VER \
  --build-arg ATF_SUM=$ATF_SUM \
  --build-arg MTLS_VER=$MTLS_VER \
  --build-arg MTLS_SUM=$MTLS_SUM \
  --build-arg HUB=$HUB \
  --build-arg BASE=$BASE \
  --build-arg BASE_EXTRA=$BASE_EXTRA \
  --build-arg ENTRYPOINT=$NAME \
  -f Dockerfile .

scan_using_grype $NAME docker:$NAME $3

docker run -it --cpus=$(nproc) \
  --name $NAME $CROSS \
  --user "$(id -u):$(id -g)" \
  --entrypoint /$NAME-buildscript.sh \
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

load u-boot
docker buildx build $LOAD \
  --build-arg SOURCE_DATE_EPOCH=$source_date_epoch \
  --build-arg UB_VER=$UB_VER \
  --build-arg UB_SUM=$UB_SUM \
  --build-arg HUB=$HUB \
  --build-arg BASE=$BASE \
  --build-arg BASE_EXTRA=$BASE_EXTRA \
  --build-arg ENTRYPOINT=$NAME \
  -f Dockerfile .

scan_using_grype $NAME docker:$NAME $3

docker run -it --cpus=$(nproc) \
  --name $NAME $CROSS \
  --user "$(id -u):$(id -g)" \
  --entrypoint /$NAME-buildscript.sh \
  -e SOURCE_DATE_EPOCH=$source_date_epoch \
  -e SOURCE_DATE=$source_date \
  -e UB_VER=$UB_VER \
  -e BUILD_LIST="$BUILD_LIST" \
  -e DEV_BUILD=$3 \
  $NAME

for dev in $LIST
do
  for loc in $dev $dev-SB $dev-TPM-SB $dev-MU-SB
  do
    docker cp $NAME:/$loc/ Builds
    sha512sum Builds/$loc/u-boot-rockchip.bin && sha512sum Builds/$loc/u-boot-rockchip.bin >> Results/release.sha512sum
    openssl dgst -SHA3-256 Builds/$loc/u-boot-rockchip.bin && openssl dgst -SHA3-256 Builds/$loc/u-boot-rockchip.bin >> Results/release.sha3sum
    sha512sum Builds/$loc/u-boot-rockchip-spi.bin && sha512sum Builds/$loc/u-boot-rockchip-spi.bin >> Results/release.sha512sum
    openssl dgst -SHA3-256 Builds/$loc/u-boot-rockchip-spi.bin && openssl dgst -SHA3-256 Builds/$loc/u-boot-rockchip-spi.bin >> Results/release.sha3sum
  done
done
docker cp $NAME:/sys.info sys.info
stop $NAME

./clean.sh cleanup.docker $5

scan_using_grype ubuntu "/ --select-catalogers debian" $3

./clean.sh cleanup.snaps

if [ "$3" = "no" ]; then
  ./clean.sh cleanup.snaps remove
  for dev in $LIST
  do
    for loc in $dev $dev-SB $dev-TPM-SB $dev-MU-SB
    do
      pushd Builds/$loc/
      dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=100 status=progress
      parted /dev/mmcblk1 mktable gpt mkpart P1 fat32 15MB 34MB -s && sleep 3
      mkfs.fat -i 00000000 -n "U-BOOT" /dev/mmcblk1p1 && mount /dev/mmcblk1p1 /mnt
      cp u-boot-rockchip.bin /mnt/u-boot-rockchip.bin
      cp u-boot-rockchip-spi.bin /mnt/u-boot-rockchip-spi.bin
      touch -c -d "$(date -R -d $source_date)" /mnt/*
      touch -c -d "$(date -R -d $source_date)" /mnt/
      dd if=/mnt/u-boot-rockchip.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
      sync && umount /mnt && dd if=/dev/mmcblk1 of=sdcard.img bs=1M count=35 status=progress
      touch -c -d "$(date -R -d $source_date)" sdcard.img
      popd
      sha512sum Builds/$loc/sdcard.img >> Results/release.sha512sum
    done
  done
  dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=100 status=progress
  dd if=Builds/RP64-rk3399-TPM-SB/sdcard.img of=/dev/mmcblk1 conv=notrunc status=progress
else
  dd if=/dev/zero of=/dev/mmcblk1 bs=1M count=100 status=progress
  dd if=Builds/RP64-rk3399-TPM-SB/u-boot-rockchip.bin of=/dev/mmcblk1 seek=64 conv=notrunc status=progress
fi
pushd Results/
  sed -i 's/Builds/..\/Builds/g' release.sha512sum
  echo "" && echo "" >> release.sha512sum
  echo "# 0mniteck's Current GPG Key ID: 287EE837E6ED2DD3" >> release.sha512sum && echo "" >> release.sha512sum
  echo "# Source Date Epoch: $source_date_epoch" >> release.sha512sum
  echo "# Build Complete: $(date -u '+on %D at %R UTC')" >> release.sha512sum && echo "Build Complete: $(date -u '+on %D at %R UTC')"
  echo "# Base Build System: $(uname -o) $(uname -r) $(uname -p) $(lsb_release -ds) $(lsb_release -cs) $(uname -v)"  >> release.sha512sum
  echo $(cat ../sys.info) >> release.sha512sum
popd
if [ "$check_file" = "1" ]; then
  pushd Results/
    cp /tmp/release.last.sha512sum release.last.sha512sum
    sha512sum -c release.last.sha512sum
    rm -f /tmp/release.last.sha512sum && rm -f release.last.sha512sum
  popd
fi
echo "Successful Build of U-Boot v$UB_VER on $build_message_timestamp W/ TF-A $ATF_VER & OP-TEE v$OPT_VER" > status.build
