#!/usr/bin/pkexec /bin/bash

## Available Commands:
# git.cleanup
# git.cleanup.(cache)
# dir.cleanup
# cleanup.docker (unmount)
# cleanup.docker.(remove) (unmount)
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
  chmod -R +x Buildscripts/
  chmod -R +x Configs/
  mkdir -p .git/Cache
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
    rm -f *.info && rm -f release.* && rm -f vars.* && rm -f builder.*
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
    snap disable docker 2>/dev/null && wait
    rm -f -r /var/snap/docker/*
    rm -f -r /var/lib/snapd/cache/*
    sleep 5
  fi
  if [[ "$2" == *unmount* ]]; then
    snap disable docker 2>/dev/null && wait
    umount -f /dev/mapper/Luks-Signal 2>/dev/null && wait
    sleep 5
    systemd-cryptsetup detach Luks-Signal 2>/dev/null && wait
  fi
  if [[ "$1" == *cleanup.docker.remove* ]]; then
    rm -f -r /var/snap/docker
    snap enable docker 2>/dev/null && wait
    snap remove docker --purge 2>/dev/null && wait
    snap remove docker --purge 2>/dev/null && wait
    snap remove core24 --purge 2>/dev/null && wait
  else
    snap enable docker 2>/dev/null && wait
    snap remove docker 2>/dev/null && wait
  fi
  if [[ $(snap list) == *disabled* ]]; then
    snap list
  fi
  networkctl delete docker0 2>/dev/null && wait
  networkctl delete docker1 2>/dev/null && wait
fi

if [[ "$1" == *cleanup.snaps* ]]; then
  if [[ "$1" == *cleanup.snaps.remove* ]]; then
    snap remove syft --purge 2>/dev/null && wait
    snap remove grype --purge 2>/dev/null && wait
    rm -f -r /root/Library
  fi
  rm -f -r /root/getter* && rm -f -r /root/grype-scratch* && rm -f -r /root/syft && rm -f -r /root/6 && rm -f -r $HOME/.cache/grype && rm -f -r $HOME/.cache/syft && rm -f -r /tmp/grype-scratch* && rm -f -r /tmp/getter* && rm -f $HOME/.grype.yaml
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
    rm -f /tmp/release.last.* && rm -f release.last.*
    rm -f sys.* && rm -f status.* && rm -f vars.* && rm -f builder.*
    for con in $TARGETS
    do
      rm -f $con/tmp
    done
  popd
fi
exit 0
