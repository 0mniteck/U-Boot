#!/bin/bash

export HUB="0mniteck/debian"
export BASE="04-24-2025@sha256:8299af4dccd49bfdbba56aa539842565ba867c5fb39677fc58029dee1ec87791"
export BASE_EXTRA="04-24-2025@sha256:a0dfda9a0b10d76a345ab50bd8ebedfd65db09818f68844de25d6874559c20b8"

export OPT_VER="4.5.0"
export OPT_SUM="7e3270a01425ca57213a8bb12feaf0e68b85673df5496487bbfc86657147888859db3da947a8496adae24840874743bf19f6468c2d512a62befb867d9581f30a"
export ATF_VER="lts-v2.12.1"
export ATF_SUM="60cce90bb1b61bad92e1bb5a78f2063835dbcc47e8e7ca78fff90427836f5680f36c0d22878bc8f8b079c3d4e63304e7e9b55dc3b94d3af2edc03e6b9eb26c86"
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

chmod +x Configs/*
sudo apt install -y bc dosfstools parted screen snapd
git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
./clean.sh $CLEAN && sudo screen -c vars.env -L -Logfile builder.log bash -c './re-run.sh '$(($EPOCH))' '$CLEAN' '$TEST
echo "" && cat builder.log | grep -n "Checksum Matched! " && echo "" && cat Results/release.sha512sum && echo ""
mv builder.log Results/builder.log && status="$(cat status.build)" && ./clean.sh cleanup && ls -la Builds/*
read -p "$status: --> sign/commit/push" && ./git.sh "$status" "$TAG"
