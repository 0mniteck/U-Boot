#!/bin/bash

## Available Commands:
# git.cleanup
# git.cleanup.(cache)
# dir.cleanup
# cleanup.docker
# cleanup.docker.(unmount)
# cleanup.docker.(remove)...(unmount)
# cleanup.snaps
# cleanup.snaps.(remove)
# tmp.cleanup

do_update() {
  ./git.sh update
}

if [[ "$1" == *git.cleanup* ]]; then
  git reset --hard
  git clean -xfd
  do_update
  if [[ "$1" == *git.cleanup.cache* ]]; then
    rm -r -f .git/Cache
  fi
  mkdir -p .git/Cache
  rm -f builder.* && rm -f build.* && rm -f release.*
  echo '' > Results/release.sha512sum && echo '' > Results/release.sha3sum && echo '' > Results/build.info
fi

if [ "$1" = "dir.cleanup" ]; then
  pushd Builds/
    for dev in $LIST
    do
      for loc in $VARIANTS
      do
        find $dev$loc/. ! -type d -delete
        touch $dev$loc/tmp
      done
      find $dev/. ! -type d -delete
      touch $dev/tmp
    done
    for arch in $ARCHS
    do
      find $arch/. ! -type d -delete
      touch $arch/tmp
    done
  popd
  pushd Results/
    cp release.sha512sum /tmp/release.last.sha512sum
    rm -f Results/builder.* && rm -f Results/build.* && rm -f Results/release.*
    find . ! -type d -delete # Will be removed
    for con in $TARGETS
      do
        mkdir -p $con
        find $con/. ! -type d -delete
        touch $con/tmp
      done
  popd
fi

if [[ "$1" == *cleanup.docker* ]]; then
  if [[ "$1" == *cleanup.docker.remove* ]]; then
    snap disable docker
    rm -f -r /var/snap/docker/*
    rm -f -r /var/lib/snapd/cache/*
    sleep 5
  fi
  if [[ "$1" == *cleanup.docker.unmount* ]]; then
    snap disable docker
    umount -f /dev/mapper/Luks-Signal
    sleep 5
    systemd-cryptsetup detach Luks-Signal
  fi
  if [[ "$1" == *cleanup.docker.remove* ]]; then
    rm -f -r /var/snap/docker
    snap enable docker
    snap remove docker --purge
    snap remove docker --purge
    snap remove core24 --purge
  else
    snap enable docker
    snap remove docker
  fi
  if [[ $(snap list) == *disabled* ]]; then
    snap list
  fi
  networkctl delete docker0
  networkctl delete docker1
fi

if [[ "$1" == *cleanup.snaps* ]]; then
  if [[ "$1" == *cleanup.snaps.remove* ]]; then
    snap remove syft --purge
    snap remove grype --purge
  fi
  rm /root/getter* -f -r && rm /root/grype-scratch* -f -r && rm /root/syft -f -r && rm /root/6 -f -r && rm /root/Library -f -r && rm -f -r $HOME/.cache/grype && rm -f -r $HOME/.cache/syft && rm -f -r /tmp/grype-scratch* && rm -f -r /tmp/getter*
fi

if [ "$1" = "tmp.cleanup" ]; then
  pushd Builds/
    for dev in $LIST
    do
      for loc in $VARIANTS
      do
        rm -f $dev$loc/tmp
      done
      rm -f $dev/tmp
    done
    for arch in $ARCHS
    do
      rm -f $arch/tmp
    done
  popd
  pushd Results/
    for con in $TARGETS
    do
      rm -f $con/tmp
    done
  rm -f builder.*
  popd
  rm -f build.info && rm -f status.build && rm -f sys.info && rm -f vars.env
fi
exit 0
