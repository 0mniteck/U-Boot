#!/bin/bash

export HUB="0mniteck/debian"
export BASE="07-04-2025@sha256:014f2ff746838ce4dddbde77ffc53a5941e7f0d9fbc2226654b22e586974c852"
export BASE_EXTRA="07-04-2025@sha256:870d90e2b690b2abb786eed1f308c06f90366309d95d3fdbb170c34733a2dece"

export OPT_VER="4.6.0"
export OPT_SUM="817f0f8135dc855f1848047e2e58492a12613d0920c74620c4d4f84ac6019cdaab44cd36f3682de7df550f600ffd34a98924c1ec8da31a3826770db6f5491a83"
export ATF_VER="lts-v2.12.4"
export ATF_SUM="acbebe93153c8bd523f8103910285fe8672b25011ecfeee9c0890b44916e524b59d9900916c03172ae7bf7b9d2eb4ff568e58829a6edb58df7634f2d172d6271"
export UB_VER="2025.04"
export UB_SUM="2c3d2345d4f9e2e3925102e1cdc7284d682c90a8021a7ced9443a7558736a88617b764c9c6cc72578040ac29a98ffd23286dbd46a1127e30ed6363d5271aa804"

export BUILD_LIST="RP64-rk3399:rockpro64-rk3399_defconfig PBP-rk3399:pinebook-pro-rk3399_defconfig R5B-rk3588:rock5b-rk3588_defconfig"
export LIST="RP64-rk3399 PBP-rk3399 R5B-rk3588"
export ARCHS="rk3399 rk3588"

while getopts ":c:d:r:t:" opt; do
    case $opt in
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
for env in HUB^$HUB BASE^$BASE BASE_EXTRA^$BASE_EXTRA OPT_VER^$OPT_VER OPT_SUM^$OPT_SUM ATF_VER^$ATF_VER ATF_SUM^$ATF_SUM UB_VER^$UB_VER UB_SUM^$UB_SUM
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
sed -i '10d' vars.env

echo "Clean Build: $CLEAN"
echo "Override Source Epoch: $EPOCH"
echo "Tag Release: $TAG"
echo "Test Build: $TEST"
sleep 5

sudo apt install -y ansifilter bc dosfstools parted screen snapd
git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
./clean.sh $CLEAN && sudo screen -c vars.env -L -Logfile builder.log bash -c './re-run.sh '$(($EPOCH))' '$CLEAN' '$TEST
echo "" && cat builder.log | grep -n "Checksum Matched! " && echo "" && cat Results/release.sha512sum && echo ""
mv builder.log Results/builder.log && status="$(cat status.build)" && ./clean.sh cleanup && ls -la Builds/*
read -p "$status: --> sign/commit/push" && ./git.sh "$status" "$TAG"
