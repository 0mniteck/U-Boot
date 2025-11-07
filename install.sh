#!/usr/bin/pkexec /bin/bash

## Available Commands:
# apt.update
# purge.snapd
# install.docker.(cross)
# cleanup.docker.(remove) (unmount/purge)
# cleanup.snaps.(remove) (install)

apt_update() {
  apt update
  apt upgrade -y
  apt install -y bc dosfstools parted screen snapd systemd-cryptsetup
}

add_user() {
  groupadd docker
  usermod -aG docker $1
  chown root:docker /var/run/docker.sock
  chmod 660 /var/run/docker.sock
}

purge_snapd() {
  rm -f -r /var/snap/docker/*
  rm -f -r /var/lib/snapd/cache/*
  crypt_unmount
  networkctl delete docker0 2>/dev/null && wait
  networkctl delete docker1 2>/dev/null && wait
  apt remove --purge snapd -y
  rm -f -r /var/snap/docker
  apt install ubuntu-server-minimal -y
  snap install ufw
  ufw allow ssh
  printf 'y\n' | ufw enable
}

crypt_mount() { #1 = device
  systemd-cryptsetup attach Luks-Signal /dev/$1
  sleep 5
  mount /dev/mapper/Luks-Signal /var/snap/docker
}
crypt_unmount() {
  umount -f /dev/mapper/Luks-Signal 2>/dev/null && wait
  sleep 5
  systemd-cryptsetup detach Luks-Signal 2>/dev/null && wait
}

if [[ "$1" == *apt.update* ]]; then
  apt_update
fi

if [[ "$1" == *purge.snapd* ]]; then
  purge_snapd
fi

if [[ "$1" == *install.docker.cross* ]]; then
  snap install docker --revision=3377
  if [[ "$2" != "" ]]; then
    crypt_mount $2
  fi
  add_user $3
elif [[ "$1" == *install.docker* ]]; then
  snap install docker --revision=3380 && systemctl stop snap.docker.nvidia-container-toolkit
  systemctl disable snap.docker.nvidia-container-toolkit
  if [[ "$2" != "" ]]; then
    crypt_mount $2
  fi
  add_user $3
fi

if [[ "$1" == *cleanup.docker* ]]; then
  if [[ "$1" == *cleanup.docker.remove* ]]; then
    snap disable docker 2>/dev/null && wait
    rm -f -r /var/snap/docker/*
    rm -f -r /var/lib/snapd/cache/*
    sleep 5
  fi
  if [[ "$2" != "" ]]; then
    snap disable docker 2>/dev/null && wait
    crypt_unmount
  fi
  if [[ "$1" == *cleanup.docker.remove* ]]; then
    snap enable docker 2>/dev/null && wait
    snap remove docker --purge 2>/dev/null && wait
    snap remove docker --purge 2>/dev/null && wait
    snap remove core24 --purge 2>/dev/null && wait
    rm -f -r /var/snap/docker
    if [[ "$2" == *purge* ]]; then
      purge_snapd
    fi
  else
    snap enable docker 2>/dev/null && wait
    snap remove docker 2>/dev/null && wait
  fi
  if [[ $(snap list) == *disabled* ]]; then
    snap list
  fi
  networkctl delete docker0 2>/dev/null && wait
  networkctl delete docker1 2>/dev/null && wait
  mkdir -p /var/snap/docker
fi

if [[ "$1" == *cleanup.snaps* ]]; then
  if [[ "$1" == *cleanup.snaps.remove* ]]; then
    snap remove syft --purge 2>/dev/null && wait
    snap remove grype --purge 2>/dev/null && wait
    rm -f -r /root/Library
  fi
  rm -f -r /root/getter* && rm -f -r /root/grype-scratch* && rm -f -r /root/syft && rm -f -r /root/6 && rm -f -r $HOME/.cache/grype && rm -f -r $HOME/.cache/syft && rm -f -r /tmp/grype-scratch* && rm -f -r /tmp/getter* && rm -f $HOME/.grype.yaml
  if [[ "$2" == *install* ]]; then
    snap install syft --classic 2>/dev/null && wait
    snap install grype --classic 2>/dev/null && wait
  fi
fi
