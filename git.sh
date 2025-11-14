#!/bin/bash
env | sort
## Available Commands:

# ./git.sh check
# ./git.sh reset
# ./git.sh update

# Host UBoot ## Add to ~/.ssh/config for SSH support, recommend ecdsa-sk or ed25519_sk.
#    Hostname github.com
#    IdentityFile ~/.ssh/id_ecdsa_sk
#    IdentitiesOnly yes

yubi_check() {
  while [[ $(lsusb) != *Yubikey* ]]; do printf "\rPlease insert yubikey...\033[K"; done;
  if [[ $(ls -la /dev/hidraw0) = *root* ]]; then
    pkexec chown $(whoami):$(whoami) /dev/hidraw*
  fi
}

git_reset() {
  git reset --hard
  git clean -xfd
  if [[ $(<~/.ssh/config) == *UBoot* ]]; then
    export GPG_TTY=$(tty)
    eval `ssh-agent -s`
    ssh-add ~/.ssh/id_ecdsa_s*[!.pub]
  fi
}

git_update() {
  echo "Fetching recent changes..."
  if [[ $(<~/.ssh/config) == *UBoot* ]]; then
    yubi_check
    git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
    read -p "Origin set to SSH; Continue git pull..."
  fi
  git pull $(git remote -v | awk '{ print $2 }' | tail -n 1) $(git rev-parse --abbrev-ref HEAD)
}

if [[ "$1" == *check* ]]; then
yubi_check
exit 0
elif [[ "$1" == *reset* ]]; then
git_reset
exit 0
elif [[ "$1" == *update* ]]; then
git_update
exit 0
fi

git status && git add -A && git status
if [[ $(<~/.ssh/config) == *UBoot* ]]; then
  yubi_check
fi

pkexec --keep-cwd git commit -a -S -m "$1" && sleep 5 && git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD):Docker
if [ "$2" != "" ]; then
  pkexec --keep-cwd git tag -a "$2" -s -m "Tagged Release $2" && sleep 5 && git push origin "refs/tags/$2"
fi
