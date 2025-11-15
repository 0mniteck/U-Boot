#!/bin/bash
env | sort >> Results/Env/clean.env && echo "" >> Results/Env/clean.env
## Available Commands:

# $PWD/clean.sh git.cleanup
# $PWD/clean.sh git.cleanup.(cache)
# $PWD/clean.sh tmp.cleanup

env_elimnator() { # 1 = $PWD/file.sh, # 2 = logname
  sleep 5 && > $2.log && env -i - env TERM=screen - screen -h 10000 -L -Logfile $2.log env -u TERM -u TERMCAP -u STY - PATH=/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin bash --noprofile --norc -c $1
}

do_clean() {
  env_elimnator "$PWD/git.sh reset" Results/logs/git
}

do_update() {
  env_elimnator "$PWD/git.sh update" Results/logs/git
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
    rm -f *.info && rm -f release.* && && rm -f *.set rm -f logs/*.log && rm -f env/*.env && rm -f *.set
    find . ! -type d -delete # Will be removed
    cp ../defaults defaults.set
    for con in $TARGETS
    do
      mkdir -p $con
      find $con/. ! -type d -delete
      touch $con/tmp
    done
    pushd env
      touch tmp
    popd
    pushd logs
      touch tmp
    popd
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
    rm -f sys.* && rm -f status.* && rm -f *.log
    for con in $TARGETS
    do
      rm -f $con/tmp
    done
    pushd env
      rm -f tmp
    popd
    pushd logs
      rm -f tmp
    popd
  popd
fi
exit 0
