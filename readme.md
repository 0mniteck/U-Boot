# U-Boot RockChip <sup><sub>- rk3399 (HARDENING), & rk3588 (TESTING)</sub></sup>

### Project Goals
* [ ] Enable TPM Support
  * [ ] Check if [new patches](https://github.com/radxa-pkg/radxa-overlays/pull/385) fixed problem
* [x] Remove rkbin dependency from rk3568 & rk3588
  * [x] TF-A upstreamed initial patches from rockchip
  * [x] U-boot modifications to use u-boot-tpl vs rockchip-tpl
  * [x] Resolve rk3568 issues - Enable TPL
  * [ ] Resolve rk3568 issues - SPL_MAX
* [x] Enable UEFI Secure Boot with Root CA only on a Yubikey
  * [ ] Try higher bit RSA/ECDSA keys to protect against [Quantum Attacks](https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqbENJQmx3b3pWV2F0YU9tMG8yRGxTb1c1cElQUXxBQ3Jtc0ttRTJtRFlmMGE4cnQxa2Q0WE54VTNnM05BSGlGdVExMkJicWszTlBHRE0tNk4xUDBhQU1EMVY4Zm8ySVNfa0pIbDVockhiUzBjLWs0YnZiRlJPRkFaV3BvUFc1T0t1VWR3RFV1VW1KNV9xdGdZOEYtYw&q=https%3A%2F%2Fwww.csoonline.com%2Farticle%2F3562701%2Fchinese-researchers-break-rsa-encryption-with-a-quantum-computer.html&v=_iSih4KI_qQ)
    * [x] 4096 bit Fails on 5.7.1 Yubikey
    * [ ] Test 3072 bit RSA
    * [ ] Test ECDSA keys
      * [ ] Create hybrid scheme fallback and use dbx revocations
* [ ] Sign FIT images and enable COT (Chain of Trust) in ATF
* [ ] [Setup Secure Bootflow](https://labs.withsecure.com/content/dam/labs/docs/2020-05-u-booting-securely-wp-final.pdf)
  * [ ] U-Boot Secure boot with verified FIT -> TF-A -> Default: run bootcmd -> UEFI Secure Boot
    * [x] Protect against untrusted environment variables
    * [x] Restrict to BOOTM
      * [ ] Remove BOOTDEV's
    * [ ] Change bootcmd to `efiload; reset;`
    * [ ] Enable STACKPROTECTION for rk3588
    * [ ] Block dropping down to shell
* [x] Generate SBOM at buildtime
  * [x] Scan with Grype
  * [x] Display Status
* [x] Fine tune for reproducibility and ephemerality
  * [ ] Use-once model for next secure boot signing (Reset Yubikey after initial signing)
    * [ ] 2025 Q4 signing
      * [ ] Debian from trixie ISO shimaa64efi/bootaa64.efi
      * [ ] Ubuntu from 25.04 ISO shimaa64.efi/bootaa64.efi
        * [ ] Update autoinstall to current release
  * [ ] Always erase & flash from ring-0
  * [x] Convert to docker build
    * [x] Build variants in one branch
    * [x] Make reproducible debian docker images

## Build Instructions/Usage:

### Build:

```
buildscript.sh
 -a {Cross-Compile: yes/No}
 -c {Clean: Yes/no}
 -d {Date: source_date_epoch}
 -r {Release-tag: tagname}
 -t {Test-mode: yes/No}
```

#### To compile current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -r "tagname"
```

#### To cross-compile current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -r "tagname" -a yes
```

#### To compile for reproducibility run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git -b "tagname" && \
cd U-Boot && \
./buildscript.sh -d "$(cat Results/release.sha512sum | grep Epoch | cut -d ' ' -f5)"
```

### Requirements:

* [ ] Debian based OS already running on an ARM64 CPU

* [ ] Any microSD in the /dev/mmcblk1 slot

## 

### [Docs:](https://github.com/0mniteck/U-Boot/tree/Docs/docs)

--> [FLASHING AND INSTALLING](https://github.com/0mniteck/U-Boot/blob/Docs/docs/FLASH.md)  --> [FLASHING DEMO](https://u-boot.omniteck.com/#content)

--> [SIGNING YOUR OWN](https://github.com/0mniteck/U-Boot/blob/Docs/docs/SIGN.md)
