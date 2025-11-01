#!/bin/bash

do_update() {
  echo "Fetching recent changes..."
  if [ "$(echo "$(cat "$HOME/.ssh/config" | grep UBoot)")" != "" ]; then
    while [ "$(echo "$(lsusb | grep Yubikey)")" = "" ]; do printf "\rPlease insert yubikey...\033[K"; done
    git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
    echo "" && read -p "Origin set to SSH; Continue git pull..."
  fi
  git pull $(git remote -v | awk '{ print $2 }' | tail -n 1) $(git rev-parse --abbrev-ref HEAD)
}

if [ "$1" = "update" ]; then
do_update
exit 0
fi

if [ "$(echo "$(cat "$HOME/.ssh/config" | grep UBoot)")" != "" ]; then
  export GPG_TTY=$(tty)
  eval `ssh-agent -s`
  ssh-add $HOME/.ssh/id_ecdsa_s*[!.pub]
fi
git status && git add -A && git status
if [ "$(echo "$(cat "$HOME/.ssh/config" | grep UBoot)")" != "" ]; then while [ "$(echo "$(lsusb | grep Yubikey)")" = "" ]; do printf "\rPlease insert yubikey...\033[K"; done; fi
git commit -a -S -m "$1" && sleep 5 && git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD):Docker
if [ "$2" != "" ]; then
  git tag -a "$2" -s -m "Tagged Release $2" && sleep 5 && git push origin "refs/tags/$2"
fi
