#!/bin/bash

GPG_TTY=$(tty)
export GPG_TTY
eval `ssh-agent -s`
ssh-add $HOME/.ssh/id_ecdsa_s*[!.pub]
git status && git add -A && git status
git commit -a -S -m "$1" && sleep 5 && git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD):Docker
if [ "$2" != "" ]; then
  git tag -a "$2" -s -m "Tagged Release $2" && sleep 5 && git push origin "refs/tags/$2"
fi
