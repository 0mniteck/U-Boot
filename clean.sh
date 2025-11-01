#!/bin/bash

if [ "$1" = "git.cleanup" ]; then
  git reset --hard
  git clean -xfd
  echo "Fetching recent changes..."
  if [ "$(echo "$(cat "$HOME/.ssh/config" | grep UBoot)")" != "" ]; then
    while [ "$(echo "$(lsusb | grep Yubikey)")" = "" ]; do printf "\rPlease insert yubikey...\033[K"; done
    git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
    echo "" && read -p "Origin set to SSH; Continue git pull..."
  fi
  git pull $(git remote -v | awk '{ print $2 }' | tail -n 1) $(git rev-parse --abbrev-ref HEAD)
  mkdir -p .git/Cache
fi

if [ "$1" = "pre.cleanup" ]; then
  pushd Builds/
    find . ! -type d -delete
    for dev in $LIST
    do
      for loc in $($(echo $VARIANTS))
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
    cp release.sha512sum /tmp/release.last.sha512sum
    find . ! -type d -delete
    for con in $TARGETS
      do
        mkdir -p $con
        touch $con/tmp
      done
  popd
fi

if [ "$1" = "cleanup.cache" ]; then
  rm -r -f .git/Cache
  mkdir -p .git/Cache
fi

if [ "$1" = "cleanup.docker" ]; then
  snap disable docker
  rm -f -r /var/snap/docker/*
  if [ "$2" != "" ]; then
    umount -f /dev/mapper/Luks-Signal
    sleep 5
    systemd-cryptsetup detach Luks-Signal
  fi
  rm -f -r /var/snap/docker
  sleep 5
  snap enable docker
  snap remove docker --purge
  snap remove docker --purge
  networkctl delete docker0
  rm -f -r /var/lib/snapd/cache/*
fi

if [ "$1" = "cleanup.snaps" ]; then
  if [ "$2" = "remove" ]; then
    snap remove syft --purge
    snap remove grype --purge
  fi
  rm /root/getter* -f -r && rm /root/grype-scratch* -f -r && rm /root/syft -f -r && rm /root/6 -f -r && rm /root/Library -f -r && rm -f -r $HOME/.cache/grype && rm -f -r $HOME/.cache/syft && rm -f -r /tmp/grype-scratch* && rm -f -r /tmp/getter*
fi

if [ "$1" = "cleanup" ]; then
  pushd Builds/
    for dev in $LIST
    do
      for loc in $VARIANTS
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
    for con in $TARGETS
    do
      rm -f $con/tmp
    done
  popd
  rm -f status.build && rm -f sys.info && rm -f vars.env
fi
exit
