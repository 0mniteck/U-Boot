#!/usr/bin/pkexec /bin/bash

cd $3
source defaults

## Available Commands:
# cleanup.docker (unmount)
# cleanup.docker.(remove) (unmount)
# cleanup.snaps
# cleanup.snaps.(remove)

apt_update() {
  apt update
  apt upgrade -y
  apt install -y bc dosfstools parted screen snapd systemd-cryptsetup
}

if [[ "$1" == *apt.update* ]]; then
  apt_update
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
