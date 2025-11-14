#!/bin/bash
env | sort > /.env

env_elimnator() { # 1 = $PWD/file.sh, # 2 = logname
  sleep 5 && > $2.log && env -i - env TERM=screen - screen -h 10000 -L -Logfile $2.log env -u TERM -u TERMCAP -u STY - PATH=/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin bash --noprofile --norc -c $1
}

## Available Commands:

# ./clean.sh git.cleanup
# ./clean.sh git.cleanup.(cache)
# ./clean.sh tmp.cleanup

do_clean() {
  env_elimnator "$PWD/git.sh reset" Results/git
}
do_update() {
  env_elimnator "$PWD/git.sh update" Results/git
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
  rm -f defaults.set
  cp defaults $_
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
    rm -f *.info && rm -f release.* && rm -f builder.*
    find . ! -type d -delete # Will be removed
    for con in $TARGETS
      do
        mkdir -p $con
        find $con/. ! -type d -delete
        touch $con/tmp
      done
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
    rm -f sys.* && rm -f status.* && rm -f builder.*
    for con in $TARGETS
    do
      rm -f $con/tmp
    done
  popd
fi
exit 0
