#!/bin/bash
source ./defaults
env | sort >> Results/env/clean.env && echo "" >> Results/env/clean.env
## Available Commands:

# $PWD/clean.sh git.cleanup
# $PWD/clean.sh git.cleanup.(cache)
# $PWD/clean.sh tmp.cleanup

do_clean() {
  $PWD/git.sh reset
}

do_update() {
  $PWD/git.sh update
}

if [[ "$1" == *git.cleanup* ]]; then
  do_clean
  do_update
  if [[ "$1" == *git.cleanup.cache* ]]; then
    rm -r -f .git/Cache
  fi
  chmod -R +x Buildscripts/
  chmod -R +x Configs/
  mkdir -p .git/Cache
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
    rm -f *.info && rm -f release.* && rm -f *.set && rm -f logs/*.log && rm -f env/*.env
    find . ! -type d -delete # Will be removed
    cp ../defaults defaults.set
    for con in $TARGETS
    do
      mkdir -p $con
      find $con/. ! -type d -delete
      touch $con/tmp
    done
    touch env/tmp
    touch logs/tmp
  popd
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
    rm -f sys.* && rm -f status.*
    for con in $TARGETS
    do
      rm -f $con/tmp
    done
    rm -f env/tmp
    rm -f logs/tmp
  popd
fi
exit 0
