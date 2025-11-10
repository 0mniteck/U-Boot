#!/bin/bash
# ── Configuration for defaults ─ Source File ─────────────────────────────────
source defaults
# ── User Config Inputs ───────────────────────────────────────────────────────
while getopts ":a:c:d:e:m:t:w:z:" opt; do
  case $opt in
  a) # Alternate List (yes/No)
    ALT="$OPTARG"
    ;;
  c) # Clean Directories (Yes/no)
    CLEAN="$OPTARG"
    ;;
  d) # Developer Build [Skip some steps] (yes/No)
    DEV="$OPTARG"
    ;;
  e) # SOURCE_DATE_EPOCH [For reproducibility] (source_date_epoch/"today"/"^")
    EPOCH="$OPTARG"
    ;;
  m) # Mount External [U2F Backed Luks] Partition ex. "mmcblk1p1"
    MOUNT="$OPTARG"
    ;;
  t) # Tag Release refs/tags/("tagname") *Required
    TAG="$OPTARG"
    ;;
  w) # Cross Compile (yes/No)
    CROSS="$OPTARG"
    ;;
  z) # Target Selection ("target1,target2,all")
    TARGET="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$opt" >&2
    ;;
  :)
    echo "Option -$opt requires an argument." >&2
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
rm -f Results/defaults.set
cp defaults $_
if [ "$ALT" = "" ]; then
  ALT="no"
fi
if [ "$ALT" = "yes" ]; then
  export BUILD_LIST="PT2-rk3566:pinetab2-rk3566_defconfig"
  export LIST="PT2-rk3566"
  export ARCHS="rk3568"
  sed -i s/"$(grep "BUILD_LIST" defaults | awk -F'"' '{print $2}')"/"$BUILD_LIST"/ Results/defaults.set
  sed -i s/"$(grep "LIST" defaults | awk -F'"' '{print $2}')"/"$LIST"/ Results/defaults.set
  sed -i s/"$(grep "ARCHS" defaults | awk -F'"' '{print $2}')"/"$ARCHS"/ Results/defaults.set
else
  export ARCHS="$(echo $ARCHS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
fi
# ── Target Validation ────────────────────────────────────────────────────────
TRGLIST="(edk2|arm-trusted|optee|u-boot|ubuntu|base|base_extra)"
if [[ -z "$TARGET" || "$TARGET" == *all* ]]; then
  export TARGETS="$(echo $TARGETS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
  TARGET="$TARGETS"
elif [[ "$TARGET" =~ $TRGLIST ]]; then
  for TRG in $TARGET; do
    if [[ "$TRG" =~ $TRGLIST ]]; then
      export TARGETS="$TARGET"
      export TARGETS="$(echo $TARGETS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
      sed s/"$(grep "TARGETS" defaults | awk -F'"' '{print $2}')"/"$TARGETS"/ defaults > Results/defaults.set
    else
      echo "INVALID TARGET: $TRG"
      exit 1
    fi
  done
else
  echo "INVALID TARGET LIST: $TARGET"
  exit 1
fi
# ── Update + Clean ───────────────────────────────────────────────────────────
if [[ $(which pkexec) = "" ]]; then
  sudo apt update && sudo apt upgrade -y && sudo apt install -y bc dosfstools parted pkexec screen snapd systemd-cryptsetup
  sudo -K
else
  $PWD/install.sh apt.update
fi
if [[ "$CLEAN" = "yes" && "$DEV" != "yes" ]]; then
  ./clean.sh git.cleanup.cache
elif [ "$CLEAN" = "yes" ]; then
  ./clean.sh git.cleanup
fi
# ── Check Variables ──────────────────────────────────────────────────────────
  ENV=$(sha512sum defaults)
pushd Results
  if [[ $ENV == *068e37dc74100e179e6a2ff76e6c194aed9974b742aa7481db5000e40246a24273bb98e3a11b7c8538294128411dfeed2223ed5c7e8ddafc883bf637ec8e5914* ]]; then
    ENVV="MATCHED DEFAULTS CONFIG SHA512SUM"
  else
    echo "ERROR DEFAULTS MISSMATCH"
  fi
# ── Build Info ───────────────────────────────────────────────────────────────
  > release.sha512sum && > release.sha3sum && > build.info
  sha512sum ../defaults >> release.sha512sum && openssl dgst -SHA3-256 ../defaults >> release.sha3sum
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
  echo "export EPOCH=$EPOCH" > .set && echo "export CLEAN=$CLEAN" >> .set && echo "export DEV=$DEV" >> .set
  echo "export CR_C=$CROSS" >> .set && echo "export MOUNT=$MOUNT" >> .set && echo "export CHECK=$CHECK" >> .set
# ── Run re-run.sh to start build ─────────────────────────────────────────────
  sleep 5 && > builder.log && env -i - env TERM=screen - screen -h 10000 -L -Logfile builder.log env -u TERM -u TERMCAP -u STY - PATH=/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin SHLVL=1 bash --noprofile --norc -c ../re-run.sh
  cat builder.log | grep -n "Checksum Matched! " && mv builder.log ../../builder.log && [[ -f status.info ]] && status=$(<status.info) || echo "" && echo "Build Failed"
  echo "" && cat release.sha512sum && echo "" && cat release.sha3sum && echo "" && sed -i 's/Builds/..\/Builds/g' release.sha512sum
popd
# ── Clean + Git ──────────────────────────────────────────────────────────────
if [ "$CLEAN" = "yes" ]; then
  ./clean.sh tmp.cleanup && ls -la Builds/*
  read -p "$status: --> Continue"
  if [ "$DEV" != "yes" ]; then
    ./git.sh "$status" "$TAG"
  fi
fi
