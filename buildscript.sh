#!/bin/bash

export HUB="0mniteck/debian"
export BASE="10-16-2025@sha256:aa56598a56a68f2f7499f7613c62b5e875d7a44521c1c884fd06fc3fd42028ea"
export BASE_EXTRA="10-16-2025@sha256:6f0ab64a8af1fa60679af8cc60719e4d73204f7a8a25de74aaddf591b3875e6f"

export EDK_VER="edk2-stable202508"
export EDKP_VER="996c79ee0ed5236a0449b20f2bec4162ab4185fd"
export EDKP_SUM="fe4182bc720b76578a99f600b2cfcb015c63ae43a720807dd1b771d7e956c476154159d65f990c6a5e5a7e2eef871caf644f54f7afe40051699888afadf008f6"
export OPT_VER="4.8.0"
export OPT_SUM="147fb5086f85ea978c023759dc735003545428a3d9f83c848212ed227b59224b33e3b3549c230213df9a98da38ebfd25382e3751e8648d1d7b1a79028e9b6ac0"
export OPT_SUM2="2bdd0820535ac57765a47b5c77b12fb83716d45d904cd8363f2463c83c067fdd7a847fb5245d50eaed25026ef8ca9b737b8a94ac0bd94bf7629ed7000e422add"
export TPM_SUM="411a186326447c4ef0dd23341f0ef6f0198efd6a8c930ad379338afef6093c43c848770a551b2f44c06e7464ac7726f3207a0799905a07ad13ce9874236ccc5d"
export SSL_VER="3.6.0"
export SSL_SUM="68ccaf430b932a67a8ef344d78a0f237c4a0dc9a9a75199b05cd94d40574285b134f87ac6726a8b469ba49c05f5819281f4c140cd8240ae6f3ffe686b60af3c6"
export CROSS_VER="1.28.0"
export CROSS_SUM="367b6115ab4b0b8222dff932838f1aeffee4127f3bcf56bbd8b960bf0d4de5ddf8e55a7f77e6e4aa2651adb892a7ffaaa4dc135aa0a8b009366de820b87486e2"
export ROT_SUM="af17962e977e689d4f17944e36229189ea1c685ed13bfe462909c3d3f31d0c7a9ddb54c7840ea6cb33dc847cddf982aac6b53a8436b889db1834cab63bb935b2"
export ATF_VER="lts-v2.12.7"
export ATF_SUM="335e119c6dbca8c3e30cb08c0b45dd95022fa4f9936334ffed14b2958abd31c21791167a4145c7629525dff61bafc66b93808b68ab7d7779594270b94a1e173f"
export MTLS_VER="2.28.9"
export MTLS_SUM="9ee36b7989f5b940f69b5b84c6bec70098b4fe6e33a248c40019f4f5cfe2018b874bb8b5cf1383b05da8b7eb4a76c05b5af41f66ae56edc8a9919c71a9818707"
export UB_VER="2025.10"
export UB_SUM="07ba80c05cd37d4631b87a7a21c4b12556f8f70ff45396b34821b23826a092317d980c9fcc6b48162888e697773a24d33dd8e484933e88d353e6df3161af443f"

export BUILD_LIST="R5B-rk3588:rock5b-rk3588_defconfig RP64-rk3399:rockpro64-rk3399_defconfig PBP-rk3399:pinebook-pro-rk3399_defconfig"
export LIST="R5B-rk3588 RP64-rk3399 PBP-rk3399"
export ARCHS="rk3588 rk3399"

export VARIANTS="-SB -TPM-SB -MU-SB"
export TARGETS="edk2 optee arm-trusted u-boot ubuntu"

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
  e) # SOURCE_DATE_EPOCH [For reproducibility] (source_date_epoch/"today"/"")
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
if [ "$ALT" = "" ]; then
  ALT="no"
fi
if [ "$ALT" = "yes" ]; then
  export BUILD_LIST="PT2-rk3566:pinetab2-rk3566_defconfig"
  export LIST="PT2-rk3566"
  export ARCHS="rk3568"
fi

if [[ "$TARGET" = "" || "$TARGET" == *all* ]]; then
  TARGET="$TARGETS"
elif [[ "$TARGET" == *edk2* || "$TARGET" == *arm-trusted* || "$TARGET" == *optee* || "$TARGET" == *u-boot* ]]; then
  export TARGETS="$TARGET"
else
  echo "INVALID TARGET: $TARGET"
  exit 1
fi

if [ "$CLEAN" = "yes" ]; then
  ./clean.sh git.cleanup
fi

> vars.env
for env in HUB^$HUB BASE^$BASE BASE_EXTRA^$BASE_EXTRA EDK_VER^$EDK_VER EDKP_VER^$EDKP_VER EDKP_SUM^$EDKP_SUM OPT_VER^$OPT_VER OPT_SUM^$OPT_SUM OPT_SUM2^$OPT_SUM2 TPM_SUM^$TPM_SUM SSL_VER^$SSL_VER SSL_SUM^$SSL_SUM CROSS_VER^$CROSS_VER CROSS_SUM^$CROSS_SUM ROT_SUM^$ROT_SUM ATF_VER^$ATF_VER ATF_SUM^$ATF_SUM MTLS_VER^$MTLS_VER MTLS_SUM^$MTLS_SUM UB_VER^$UB_VER UB_SUM^$UB_SUM
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

echo "Cross-Compile: $CROSS"
echo "Clean Build: $CLEAN"
echo "Tag Release: $TAG"
echo "Developer Build: $DEV"
echo "Using Alternate List: $ALT"
echo "Targeting: $TARGET"
if [ "$EPOCH" = "" ]; then
  echo "Override Source Epoch: $(cat Results/release.sha512sum | grep Epoch | cut -d ' ' -f5)"
else
  echo "Override Source Epoch: $EPOCH"
fi
if [ "$MOUNT" != "" ]; then
  echo "Mount: /dev/$MOUNT"
fi
sleep 5

chmod -R +x Buildscripts/
chmod -R +x Configs/

if [ "$CLEAN" = "yes" ]; then
  ./clean.sh pre.cleanup
  if [ "$DEV" != "yes" ]; then
    ./clean.sh cleanup.cache
  fi
fi

sudo apt update && sudo apt install -y bc dosfstools parted screen snapd systemd-cryptsetup
> builder.log && sudo screen -c vars.env -L -Logfile builder.log bash -c './re-run.sh '$EPOCH' '$CLEAN' '$DEV' '$CROSS' '$MOUNT' '$TARGET
echo "" && cat builder.log | grep -n "Checksum Matched! " && echo "" && cat Results/release.sha512sum && echo "" && cat Results/release.sha3sum && echo ""
mv builder.log Results/builder.log && status="$(cat status.build)" && ./clean.sh cleanup && ls -la Builds/*
read -p "$status: --> sign/commit/push"
if [ "$DEV" = "no" ]; then
  ./git.sh "$status" "$TAG"
fi
