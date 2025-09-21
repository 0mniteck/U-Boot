#!/bin/bash

export HUB="0mniteck/debian"
export BASE="09-19-2025@sha256:2bd6d560a795e58358a5e5b6ba252bb16e4ab03178b8d1a09961241d72a2b03d"
export BASE_EXTRA="09-19-2025@sha256:226ea6fbb24092c3444cc7145a9a23ac7b20bb2e6ed544f5bc48f403010b1241"

export OPT_VER="4.7.0"
export OPT_SUM="a8753d9ca607c6f19e597cd0b084e5d053320ee38b7331e897dfda1bffc8212b3b75e6f74c0cd831cf6bc821d4fd0210d003389f480340fba157ff0cc7041e1e"
export OPT_SUM2="a9a85451ee0cd140fd90a92ca03ade41adf9289128e0da12a80ab18da2771961a994c7817c313aeba497d6d96cfa3788b14da14cf88a3b4dabd25c94e6efec49"
export TPM_SUM="411a186326447c4ef0dd23341f0ef6f0198efd6a8c930ad379338afef6093c43c848770a551b2f44c06e7464ac7726f3207a0799905a07ad13ce9874236ccc5d"
export SSL_VER="3.5.3"
export SSL_SUM="e1328fe1f8ab25c255ae7b4a5e109699aedb3f156f4ee47a1efc24c35937e1506412b96c3ec8726016e4ab5da27075ee0eca7716c536077e7fea5d26e6783714"
export ROT_SUM="af17962e977e689d4f17944e36229189ea1c685ed13bfe462909c3d3f31d0c7a9ddb54c7840ea6cb33dc847cddf982aac6b53a8436b889db1834cab63bb935b2"
export ATF_VER="lts-v2.12.6"
export ATF_SUM="c0ba898f652c0b4f664883b0ae87bd288d92b014ab4ae97a945c6e57b1573a4bcf9e9fd9962f292fb8c6d80c538f7c5ea795a381c631d0baef95d086b8e4b0c6"
export MTLS_VER="2.28.9"
export MTLS_SUM="9ee36b7989f5b940f69b5b84c6bec70098b4fe6e33a248c40019f4f5cfe2018b874bb8b5cf1383b05da8b7eb4a76c05b5af41f66ae56edc8a9919c71a9818707"
export UB_VER="2025.07"
export UB_SUM="2f649d22ba8da7677a4c25c3fb943e10f4bcaa9b58b5fc957632f5b84793e41aa94704792abaed7a3797a7cc335c19179d08f458c91a74e424b0798d18db2972"

export BUILD_LIST="R5B-rk3588:rock5b-rk3588_defconfig RP64-rk3399:rockpro64-rk3399_defconfig PBP-rk3399:pinebook-pro-rk3399_defconfig"
export LIST="R5B-rk3588 RP64-rk3399 PBP-rk3399"
export ARCHS="rk3588 rk3399"

while getopts ":a:c:d:e:t:w:" opt; do
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
        e) # SOURCE_DATE_EPOCH [For reproducibility] ex. "1758309600"
            EPOCH="$OPTARG"
            ;;
        t) # Tag Release refs/tags/("tagname") *Required
            TAG="$OPTARG"
            ;;
        w) # Cross Compile (yes/No)
            CROSS="$OPTARG"
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
if [ "$ALT" = "" ]; then
    ALT="no"
fi
if [ "$ALT" = "yes" ]; then
  export BUILD_LIST="PT2-rk3566:pinetab2-rk3566_defconfig"
  export LIST="PT2-rk3566"
  export ARCHS="rk3568"
fi

> vars.env
for env in HUB^$HUB BASE^$BASE BASE_EXTRA^$BASE_EXTRA OPT_VER^$OPT_VER OPT_SUM^$OPT_SUM OPT_SUM2^$OPT_SUM2 TPM_SUM^$TPM_SUM SSL_VER^$SSL_VER SSL_SUM^$SSL_SUM ROT_SUM^$ROT_SUM ATF_VER^$ATF_VER ATF_SUM^$ATF_SUM MTLS_VER^$MTLS_VER MTLS_SUM^$MTLS_SUM UB_VER^$UB_VER UB_SUM^$UB_SUM
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

echo "Cross-Compile: $CROSS"
echo "Clean Build: $CLEAN"
echo "Tag Release: $TAG"
echo "Developer Build: $DEV"
echo "Using Alternate List: $ALT"
if [ "$EPOCH" != "" ]; then
    echo "Override Source Epoch: $EPOCH"
fi
sleep 5

sudo apt install -y bc dosfstools parted screen snapd
git remote remove origin && git remote add origin git@UBoot:0mniteck/U-Boot.git
./clean.sh $CLEAN && sudo screen -c vars.env -L -Logfile builder.log bash -c './re-run.sh '$(($EPOCH))' '$CLEAN' '$DEV' '$CROSS
echo "" && cat builder.log | grep -n "Checksum Matched! " && echo "" && cat Results/release.sha512sum && echo ""
mv builder.log Results/builder.log && status="$(cat status.build)" && ./clean.sh cleanup && ls -la Builds/*
read -p "$status: --> sign/commit/push"
if [ "$DEV" = "no" ]; then
    ./git.sh "$status" "$TAG"
fi
