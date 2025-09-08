#!/bin/bash

export HUB="0mniteck/debian"
export BASE="08-23-2025@sha256:66bcadbbd6e6b56fff9196f30f0287c2419f85319eab9341a99e12d031c6592d"
export BASE_EXTRA="08-23-2025@sha256:362ba1531a982ccc0c474af60060a5854bfaaa480e94f34c101c7699b1370ba6"

export OPT_VER="4.7.0"
export OPT_SUM="a8753d9ca607c6f19e597cd0b084e5d053320ee38b7331e897dfda1bffc8212b3b75e6f74c0cd831cf6bc821d4fd0210d003389f480340fba157ff0cc7041e1e"
export OPT_SUM2="a9a85451ee0cd140fd90a92ca03ade41adf9289128e0da12a80ab18da2771961a994c7817c313aeba497d6d96cfa3788b14da14cf88a3b4dabd25c94e6efec49"
export TPM_SUM="411a186326447c4ef0dd23341f0ef6f0198efd6a8c930ad379338afef6093c43c848770a551b2f44c06e7464ac7726f3207a0799905a07ad13ce9874236ccc5d"
export ATF_VER="lts-v2.12.5"
export ATF_SUM="dfbd45eca6c437b82099d086dbce58b1615918b00e493b5e473950d43bb973599dba92d3d5ad148b841559520147e2745a07c68b959b901cf1c857e01134d302"
export UB_VER="2025.07"
export UB_SUM="2f649d22ba8da7677a4c25c3fb943e10f4bcaa9b58b5fc957632f5b84793e41aa94704792abaed7a3797a7cc335c19179d08f458c91a74e424b0798d18db2972"

export BUILD_LIST="R5B-rk3588:rock5b-rk3588_defconfig RP64-rk3399:rockpro64-rk3399_defconfig PBP-rk3399:pinebook-pro-rk3399_defconfig"
export LIST="R5B-rk3588 RP64-rk3399 PBP-rk3399"
export ARCHS="rk3588 rk3399"

while getopts ":a:c:d:r:t:" opt; do
    case $opt in
        a)
            AARCH="$OPTARG"
            ;;
        c)
            CLEAN="$OPTARG"
            ;;
        d)
            EPOCH="$OPTARG"
            ;;
        r)
            TAG="$OPTARG"
            ;;
        t)
            TEST="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$opt" >&2
            ;;
        :)
            echo "Option -$opt requires an argument." >&2
            ;;
    esac
done

if [ "$AARCH" = "" ]; then
    AARCH="no"
fi
if [ "$CLEAN" = "" ]; then
    CLEAN="yes"
fi
if [ "$TEST" = "" ]; then
    TEST="no"
fi

if [ "$TEST" = "yes" ]; then
  export BUILD_LIST="PT2-rk3566:pinetab2-rk3566_defconfig"
  export LIST="PT2-rk3566"
  export ARCHS="rk3568"
fi

> vars.env
for env in HUB^$HUB BASE^$BASE BASE_EXTRA^$BASE_EXTRA OPT_VER^$OPT_VER OPT_SUM^$OPT_SUM OPT_SUM2^$OPT_SUM2 TPM_SUM^$TPM_SUM ATF_VER^$ATF_VER ATF_SUM^$ATF_SUM UB_VER^$UB_VER UB_SUM^$UB_SUM
do
  env1=$(echo $env | cut -d'^' -f1)
  env2=$(echo $env | cut -d'^' -f2)
  env3=$(echo "setenv $env1 \"$env2\"")
  echo $env3 >> vars.env
done

printf "\"" >> vars.env
for lis in BUILD_LIST^$BUILD_LIST LIST^$LIST ARCHS^$ARCHS
do
  lis1=$(echo $lis | cut -d'^' -f1)
  lis2=$(echo $lis | cut -d'^' -f2)
  if [ $lis1 = BUILD_LIST ] || [ $lis1 = LIST ] || [ $lis1 = ARCHS ]; then
    printf "\"" >> vars.env
    echo "" >> vars.env
    printf "setenv $lis1 \"" >> vars.env
  fi
  printf "$lis2 " >> vars.env
done
echo "$lis1 \"" >> vars.env

echo "Cross-Compile: $AARCH"
echo "Clean Build: $CLEAN"
echo "Override Source Epoch: $EPOCH"
echo "Tag Release: $TAG"
echo "Test Build: $TEST"
sleep 5

sudo apt install -y ansifilter bc dosfstools parted screen snapd
git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
./clean.sh $CLEAN && sudo screen -c vars.env -L -Logfile builder.log bash -c './re-run.sh '$(($EPOCH))' '$CLEAN' '$TEST' '$AARCH
echo "" && cat builder.log | grep -n "Checksum Matched! " && echo "" && cat Results/release.sha512sum && echo ""
mv builder.log Results/builder.log && status="$(cat status.build)" && ./clean.sh cleanup && ls -la Builds/*
read -p "$status: --> sign/commit/push" && ./git.sh "$status" "$TAG"
