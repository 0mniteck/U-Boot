#!/usr/bin/env -S /usr/bin/pkexec --keep-cwd /bin/bash -c "/usr/bin/env HOME=$HOME /bin/bash -c \". $PWD/\$0\" \$0 \$1 \$2 \$3 \$4 \$5 \$6 \$7"
env | sort >> Results/env/install.env && echo "" >> Results/env/install.env
## Available Commands:

# $PWD/install.sh apt.update
# $PWD/install.sh run.install "$install" "$remove" "$(whoami)" "$cross" "$5"
# $PWD/install.sh run.uninstall "$remove" "$unmount"

apt_update() {
  apt update
  apt upgrade -y
  apt install -y bc dosfstools parted rootlesskit screen slirp4netns snapd systemd-cryptsetup uidmap
}

do_check() {
  while [[ $(lsusb) != *Yubikey* ]]; do printf "\rPlease insert yubikey...\033[K"; done;
  if [[ $(ls -la /dev/hidraw0) = *root* ]]; then
    chown $(whoami):$(whoami) /dev/hidraw*
  fi
}

purge_snapd() {
  rm -f -r /var/snap/docker/*
  rm -f -r /var/lib/snapd/cache/*
  rm -r -f $HOME/snap/
  rm -r -f /root/snap/
  rm -r -f $HOME/.local/share/docker/
  rm -r -f /usr/libexec/docker/
  sed -i "s':/home/root:':/root:'" /etc/passwd
  crypt_unmount
  networkctl delete docker0 2>/dev/null && wait
  networkctl delete docker1 2>/dev/null && wait
  apt remove --purge snapd -y
  rm -f -r /var/snap/docker
  apt install snapd -y
  snap install ufw
  ufw allow ssh
  ufw --force enable
}

check.root() { #1 = whoami
  if [[ "$HOME" == "" ]]; then
    if [[ "$1" == *root* ]]; then
      echo "do not run as root!"
      exit 1
    else
      export HOME=/home/$1
    fi
  fi
}

do_snapd_check() {
  if [[ $(snap list | grep docker | grep disabled) == *disabled* ]]; then
    snap list
    read -p "Purging snapd, couldn't re-enable docker snap.
Press any key to continue. Press CTRL+C to exit..."
    purge_snapd
  fi
}

crypt_mount() { #1 = device
  do_check
  systemd-cryptsetup attach Luks-Signal /dev/$1 && wait && sleep 1
  mount /dev/mapper/Luks-Signal /var/snap/docker && wait
}
crypt_unmount() {
  umount -f /dev/mapper/Luks-Signal 2>/dev/null && wait && sleep 1
  systemd-cryptsetup detach Luks-Signal 2>/dev/null && wait
}

install.docker() { #1 = cross, #2 = device, #3 = whoami
  check.root $3
  if [[ "$2" != "" ]]; then
    crypt_mount $2
  fi
  if [[ "$1" == *cross* ]]; then
    snap install docker --revision=3377
  elif [[ "$1" != *cross* ]]; then
    snap install docker --revision=3380
    snap stop docker
    sed -i "s':/root:':/home/root:'" /etc/passwd
    mkdir -p /home/root
    sed -i "s|\[Service\]|\[Service\]\\
User=$(echo $3)|" /etc/systemd/system/snap.docker.dockerd.service
    sed -i "s|EnvironmentFile.*|EnvironmentFile=-$(echo $HOME)/tmp/environment-rootless|" /etc/systemd/system/snap.docker.dockerd.service
    sed -i "s|ExecStart.*|ExecStart=/bin/bash -c \'$HOME/rootless.sh\'|" /etc/systemd/system/snap.docker.dockerd.service
    sed -i "s|\[Service\]|\[Service\]\\
User=$(echo $3)|" /etc/systemd/system/snap.docker.nvidia-container-toolkit.service
    systemctl daemon-reload
    snap start docker
    mkdir -p /usr/libexec/docker/cli-plugins
    ln -s /snap/docker/current/usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx
  fi
}

cleanup.docker() { #1 = remove, #2 = unmount, #3 = purge, #4 = whoami
  check.root $4
  if [[ "$1" == *remove* ]]; then
    snap disable docker 2>/dev/null && wait
      rm -r -f /root/snap/
      rm -f -r /var/snap/docker/*
      rm -f -r /var/lib/snapd/cache/*
      rm -r -f $HOME/snap/
      rm -r -f $HOME/.docker/
      rm -r -f $HOME/.local/share/docker/
      rm -r -f /usr/libexec/docker/
    sleep 5
  fi
  if [[ "$2" == "unmount" ]]; then
    snap disable docker 2>/dev/null && wait
    crypt_unmount
  fi
  if [[ "$1" == *remove* ]]; then
    snap enable docker 2>/dev/null && wait && sleep 1
    do_snapd_check
    snap remove docker --purge 2>/dev/null && wait
    snap remove docker --purge 2>/dev/null && wait
    snap remove core24 --purge 2>/dev/null && wait
    rm -f -r /var/snap/docker
    if [[ "$3" == *purge* ]]; then
      purge_snapd
    fi
  else
    snap enable docker 2>/dev/null && wait && sleep 1
    do_snapd_check
    snap remove docker 2>/dev/null && wait
  fi
  sed -i "s':/home/root:':/root:'" /etc/passwd
  networkctl delete docker0 2>/dev/null && wait
  networkctl delete docker1 2>/dev/null && wait
  mkdir -p /var/snap/docker
}

cleanup.snaps() { #1 = remove/install, #2 = whoami
  check.root $2
  if [[ "$1" == *remove* ]]; then
    snap remove syft --purge 2>/dev/null && wait
    snap remove grype --purge 2>/dev/null && wait
    rm -f -r $HOME/Library
  fi
  rm -f -r $HOME/getter* && rm -f -r $HOME/grype-scratch* && rm -f -r $HOME/syft && rm -f -r $HOME/6 && rm -f -r $HOME/.cache/grype && rm -f -r $HOME/.cache/syft && rm -f -r /tmp/getter* && rm -f -r /tmp/grype-scratch*
  if [[ "$1" == *install* ]]; then
    snap install syft --classic 2>/dev/null && wait
    snap install grype --classic 2>/dev/null && wait
  fi
}

run_install() { #1 = install, #2 = remove, #3 = whoami, #4 = cross, #5 = device
  if [[ "$5" != "" ]]; then
    unmount="unmount"
  fi
  cleanup.snaps $1 $3
  cleanup.docker $2 "$unmount" "$purge" $3
  install.docker $4 $5 $3
}

run_uninstall() { #1 = remove , #2 = unmount, #3 = whoami
  if [[ "$2" != "" ]]; then
    unmount="unmount"
  fi
  cleanup.docker $1 "$unmount" "$purge" $3
  cleanup.snaps $1 $3
}

if [[ "$1" == *apt.update* ]]; then
  apt_update
fi

if [[ "$1" == *run.install* ]]; then
  # "$install" "$remove" $(whoami) "$cross" "$5"
  if [[ $(which fan) != "" ]]; then fan 250; fi
  run_install $2 $3 $4 $5 $6
fi

if [[ "$1" == *run.uninstall* ]]; then
  # "$remove" "$unmount" $(whoami)
  run_uninstall $2 $3 $4
fi
