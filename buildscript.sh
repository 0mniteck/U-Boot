#!/bin/bash
# ── Configuration for vars.env ─ Source file for screen using setenv ─────────
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
if [ "$ALT" = "" ]; then
  ALT="no"
fi
if [ "$ALT" = "yes" ]; then
  export BUILD_LIST="PT2-rk3566:pinetab2-rk3566_defconfig"
  export LIST="PT2-rk3566"
  export ARCHS="rk3568"
fi
## ─ Target Validation ────────────────────────────────────────────────────────
TRGLIST="(edk2|arm-trusted|optee|u-boot|ubuntu|base|base_extra)"
if [[ -z "$TARGET" || "$TARGET" == *all* ]]; then
  TARGET="$TARGETS"
elif [[ "$TARGET" =~ $TRGLIST ]]; then
  for TRG in $TARGET; do
    if [[ "$TRG" =~ $TRGLIST ]]; then
      export TARGETS="$TARGET"
    else
      echo "INVALID TARGET: $TRG"
      exit 1
    fi
  done
else
  echo "INVALID TARGET LIST: $TARGET"
  exit 1
fi
export ARCHS="$(echo $ARCHS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
export TARGETS="$(echo $TARGETS | tr ' ' '\n' | sort -u | tr '\n' ' ')"
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
# ── Output to vars.env + build.info ──────────────────────────────────────────
## ─ Variables ────────────────────────────────────────────────────────────────
pushd Results
  > vars.env
  for env in HUB^$HUB BASE^$BASE BASE_EXTRA^$BASE_EXTRA EDK_VER^$EDK_VER EDKP_VER^$EDKP_VER \
  EDKP_SUM^$EDKP_SUM OPT_VER^$OPT_VER OPT_SUM^$OPT_SUM OPT_SUM2^$OPT_SUM2 TPM_SUM^$TPM_SUM \
  SSL_VER^$SSL_VER SSL_SUM^$SSL_SUM CROSS_VER^$CROSS_VER CROSS_SUM^$CROSS_SUM ROT_SUM^$ROT_SUM \
  ATF_VER^$ATF_VER ATF_SUM^$ATF_SUM MTLS_VER^$MTLS_VER MTLS_SUM^$MTLS_SUM UB_VER^$UB_VER UB_SUM^$UB_SUM
  do
    env1=$(echo $env | cut -d'^' -f1)
    env2=$(echo $env | cut -d'^' -f2)
    env3=$(echo "setenv $env1 \"$env2\"")
    echo $env3 >> vars.env
  done
  printf "\"" >> vars.env
  for lis in BUILD_LIST^$BUILD_LIST LIST^$LIST ARCHS^$ARCHS VARIANTS^$VARIANTS TARGETS^$TARGETS
  do
    lis1=$(echo $lis | cut -d'^' -f1)
    lis2=$(echo $lis | cut -d'^' -f2)
    if [ $lis1 = BUILD_LIST ] || [ $lis1 = LIST ] || [ $lis1 = ARCHS ] || [ $lis1 = TARGETS ]; then
      printf "\"" >> vars.env
      echo "" >> vars.env
      printf "setenv $lis1 \"" >> vars.env
    elif [ $lis1 = VARIANTS ]; then
      printf "\"" >> vars.env
      echo "" >> vars.env
      printf "setenv $lis1 \"\\\\\$'\\\\\\\\\\\\\\\\0' " >> vars.env
    fi
    printf -- "$lis2 " >> vars.env
  done
  echo "$lis1 \"" >> vars.env
  ENV=$(sha512sum vars.env)
## ─ Build Info ───────────────────────────────────────────────────────────────
  > release.sha512sum && > release.sha3sum && > build.info
  sha512sum vars.env >> release.sha512sum && openssl dgst -SHA3-256 vars.env >> release.sha3sum
  echo "Env Config Sum: $ENV" && echo "Env Config Sums: $ENV" >> build.info
  echo "Source Date Epoch: $EPOCH" && echo "Source Date Epoch: $EPOCH" >> build.info
  echo "Clean Build: $CLEAN" && echo "Clean Build: $CLEAN" >> build.info
  echo "Developer Build: $DEV" && echo "Developer Build: $DEV" >> build.info
  echo "Cross-Compile: $CROSS" && echo "Cross-Compile: $CROSS" >> build.info
  echo "Mounted External: /dev/$MOUNT" && echo "Mounted External: /dev/$MOUNT" >> build.info
  echo "Check Reporoducibility: $CHECK" && echo "Check Reporoducibility: $CHECK" >> build.info
  echo "Tag Release: $TAG" && echo "Tag Release: $TAG" >> build.info
  echo "Using Alternate List: $ALT" && echo "Using Alternate List: $ALT" >> build.info
  echo "Targeting: $TARGET" && echo "Targeting: $TARGET" >> build.info
# ── Run re-run.sh to start build ─────────────────────────────────────────────
  sleep 5 && > builder.log
  screen -h 10000 -c vars.env -L -Logfile builder.log env -i - bash -c "env -u LS_COLORS -u PWD -u LESSCLOSE -u LESSOPEN -u SHLVL -u _ && env PATH=/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin && env && bash -c $PWD'/../re-run.sh '$EPOCH' '$CLEAN' '$DEV' '$CROSS' '$MOUNT' '$CHECK' '"
  cat builder.log | grep -n "Checksum Matched! " && mv builder.log ../../builder.log && [[ -f status.info ]] && status=$(<status.info) || echo "Build Failed"
  echo "" && cat release.sha512sum && echo "" && cat release.sha3sum && echo ""
  sed -i 's/Builds/..\/Builds/g' release.sha512sum
popd
if [ "$CLEAN" = "yes" ]; then
  ./clean.sh tmp.cleanup && ls -la Builds/*
  read -p "$status: --> Continue"
  if [ "$DEV" != "yes" ]; then
    ./git.sh "$status" "$TAG"
  fi
fi
