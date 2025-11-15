#!/bin/bash

# ── Configuration for defaults ─ Source File ─────────────────────────────────
source defaults
# ── User Config Inputs ───────────────────────────────────────────────────────
declare -A options=(
  [a]=ALT    # Alternate List (yes/No)
  [c]=CLEAN  # Clean Directories (Yes/no)
  [d]=DEV    # Developer Build [Skip some steps] (yes/No)
  [e]=EPOCH  # SOURCE_DATE_EPOCH [^ for reproducibility] (source_date_epoch/"today"/"^")
  [m]=MOUNT  # Mount External [U2F Backed Luks] ("mmcblk1p1")
  [t]=TAG    # Tag Release refs/tags/("tagname")
  [w]=CROSS  # Cross Compile (yes/No)
  [z]=TARGET # Target Selection ("target1,target2,all")
)

while getopts ":a:c:d:e:m:t:w:z:" opt; do
  case $opt in
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    *)
      var=${options[$opt]}
      [[ -n $var ]] && printf -v "$var" "%s" "$OPTARG"
      ;;
  esac
done
# ── Defaults ─────────────────────────────────────────────────────────────────
if [ "$MOUNT" != "" ]; then
  echo "MOUNT: /dev/$MOUNT"
fi
if [ "$CROSS" = "" ]; then
  CROSS="no"
fi
if [ "$CLEAN" = "" ]; then
  CLEAN="yes"
fi
if [ "$DEV" = "" ]; then
  DEV="no"
fi
if [ "$EPOCH" = "" ]; then
  EPOCH="today"
fi
## ─ Source Date Epoch ────────────────────────────────────────────────────────
if [ "$EPOCH" = "today" ]; then
  timestamp=$(date -d $(date +%D) +%s);
  if [ "${timestamp}" != "" ]; then
    echo "SOURCE_DATE_EPOCH from today's date: $(date +%D) = @$timestamp";
    EPOCH=$((timestamp));
  else
    echo "ERROR: Can't get timestamp. Defaulting to 1.";
    EPOCH=1;
  fi
elif [[ "$EPOCH" != 0 && "$EPOCH" != "^" ]]; then
  echo "SOURCE_DATE_EPOCH: $EPOCH"
  EPOCH=$(($EPOCH))
else
  cp Results/release.sha512sum /tmp/release.last.sha512sum
  cp Results/release.sha3sum /tmp/release.last.sha3sum
  timestamp=$(</tmp/release.last.sha512sum | grep Epoch | cut -d ' ' -f5)
  if [ "${timestamp}" != "" ]; then
    echo "SOURCE_DATE_EPOCH from release.sha512sum: $(</tmp/release.last.sha512sum | grep Epoch | cut -d ' ' -f5)"
    EPOCH=$((timestamp))
    CHECK="yes"
  else
    echo "ERROR: Can't get latest commit timestamp. Defaulting to 1."
    EPOCH=1
  fi
fi
if [ "$CHECK" = "" ]; then
  CHECK="no"
fi
# ── Clean Environment Variables ──────────────────────────────────────────────
env_elimnator() { # 1 = $PWD/file.sh, # 2 = logname
  env -i - env TERM=screen - screen -h 10000 -L -Logfile $2.log env -u TERM -u TERMCAP -u STY - PATH=/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin bash --noprofile --norc -c $1
}
# ── Update + Clean ───────────────────────────────────────────────────────────
if [[ $(which pkexec) = "" ]]; then
  sudo apt update && sudo apt upgrade -y && sudo apt install -y bc dosfstools parted pkexec screen snapd systemd-cryptsetup uidmap
  sudo -K
elif [[ $(which bc) != "" && $(which dosfstools) != "" && $(which parted) != "" && $(which screen) != "" && $(which snapd) != "" && $(which systemd-cryptsetup) != "" && $(which uidmap) != "" && "$CLEAN" = "no" ]]; then
  wait
else
  ./install.sh apt.update
fi
if [[ "$CLEAN" = "yes" && "$DEV" != "yes" ]]; then
  env_elimnator "$PWD/clean.sh git.cleanup.cache" Results/logs/clean
elif [ "$CLEAN" = "yes" ]; then
  env_elimnator "$PWD/clean.sh git.cleanup" Results/logs/clean
fi
pushd Results
  if [ "$ALT" = "" ]; then
    ALT="no"
  fi
  if [ "$ALT" = "yes" ]; then
    export BUILD_LIST="PT2-rk3566:pinetab2-rk3566_defconfig"
    export LIST="PT2-rk3566"
    export ARCHS="rk3568"
    sed -i s/"$(grep "BUILD_LIST" defaults | awk -F'"' '{print $2}')"/"$BUILD_LIST"/ defaults.set
    sed -i s/"$(grep "LIST" defaults | awk -F'"' '{print $2}')"/"$LIST"/ defaults.set
    sed -i s/"$(grep "ARCHS" defaults | awk -F'"' '{print $2}')"/"$ARCHS"/ defaults.set
  else
    export ARCHS="$(echo $ARCHS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
  fi
  # ── Target Validation ────────────────────────────────────────────────────────
  TRGLIST="(crosstool-ng|openssl|edk2|arm-trusted|optee|u-boot|ubuntu|base|base_extra)"
  if [[ -z "$TARGET" || "$TARGET" == *all* ]]; then
    export TARGETS="$(echo $TARGETS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
    TARGET="$TARGETS"
  elif [[ "$TARGET" =~ $TRGLIST ]]; then
    for TRG in $TARGET; do
      if [[ "$TRG" =~ $TRGLIST ]]; then
        export TARGETS="$TARGET"
        export TARGETS="$(echo $TARGETS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
        sed -i s/"$(grep "TARGETS" defaults | awk -F'"' '{print $2}')"/"$TARGETS"/ defaults.set
      else
        echo "INVALID TARGET: $TRG"
        exit 1
      fi
    done
  else
    echo "INVALID TARGET LIST: $TARGET"
    exit 1
  fi
# ── Check Variables ──────────────────────────────────────────────────────────
  ENV=$(sha512sum defaults.set)
  if [[ $ENV == *e795c85d93a484080d0605128f9274259b0ec169a06c9948de196f2dc20d420cdcce885882bcd7b7b4c2e02661a18b9103e65d0e5f1eaa720d521851c745e126* ]]; then
    ENVV="MATCHED DEFAULTS CONFIG SHA512SUM"
  else
    ENVV="DEFAULTS MISSMATCH"
  fi
# ── Build Info ───────────────────────────────────────────────────────────────
  > release.sha512sum && > release.sha3sum && > build.info
  sha512sum defaults.set >> release.sha512sum && openssl dgst -SHA3-256 defaults.set >> release.sha3sum
  echo "Clean Build: $CLEAN" && echo "Clean Build: $CLEAN" >> build.info
  echo "Cross-Compile: $CROSS" && echo "Cross-Compile: $CROSS" >> build.info
  echo "Developer Build: $DEV" && echo "Developer Build: $DEV" >> build.info
  echo "Using Alternate List: $ALT" && echo "Using Alternate List: $ALT" >> build.info
  echo "Check Reporoducibility: $CHECK" && echo "Check Reporoducibility: $CHECK" >> build.info
  echo "Source Date Epoch: $EPOCH" && echo "Source Date Epoch: $EPOCH" >> build.info
  echo "Mounted External: /dev/$MOUNT" && echo "Mounted External: /dev/$MOUNT" >> build.info
  echo "Tag Release: $TAG" && echo "Tag Release: $TAG" >> build.info
  echo "Targeting: $TARGET" && echo "Targeting: $TARGET" >> build.info
  echo "Env Config Sum: $ENVV" && echo "Env Config Sums: $ENVV" >> build.info
  echo "export EPOCH=$EPOCH" > choices.set && echo "export CLEAN=$CLEAN" >> choices.set && echo "export DEV=$DEV" >> choices.set
  echo "export CR_C=$CROSS" >> choices.set && echo "export MOUNT=$MOUNT" >> choices.set && echo "export CHECK=$CHECK" >> choices.set
  sha512sum choices.set >> release.sha512sum && openssl dgst -SHA3-256 choices.set >> release.sha3sum
# ── Run re-run.sh to start build ─────────────────────────────────────────────
  env_elimnator $PWD/../re-run.sh logs/builder
  cat logs/builder.log | grep -n "Checksum Matched! " && mv builder.log ../../builder.log && [[ -f status.info ]] && status=$(<status.info) || echo "" && echo "Build Failed"
  echo "" && cat release.sha512sum && echo "" && cat release.sha3sum && echo "" && sed -i 's/Builds/..\/Builds/g' release.sha512sum
popd
# ── Clean + Git ──────────────────────────────────────────────────────────────
if [ "$CLEAN" = "yes" ]; then
  env_elimnator "$PWD/clean.sh tmp.cleanup" Results/logs/clean && ls -la Builds/*
  read -p "$status: --> Continue"
  if [ "$DEV" != "yes" ]; then
    env_elimnator "$PWD/git.sh '$status' '$TAG'" Results/logs/git
  fi
fi
