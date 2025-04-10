# U-Boot RockChip <sup><sub>- rk3399, rk3568, & rk3588</sub></sup>

### Project Goals
* [ ] Enable TPM Support
  * [ ] Check if [new patches](https://github.com/radxa-pkg/radxa-overlays/pull/385) fixed problem
* [x] Remove rkbin dependency from rk3568 & rk3588
  * [x] TF-A upstreamed initial patches from rockchip
  * [x] U-boot modifications to use u-boot-tpl vs rockchip-tpl
  * [ ] Resolve rk3568 issues - SPL_MAX
* [x] Enable UEFI Secure Boot with Root CA only on a Yubikey
  * [ ] Try higher bit RSA/ECDSA keys to protect against [Quantum Attacks](https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqbENJQmx3b3pWV2F0YU9tMG8yRGxTb1c1cElQUXxBQ3Jtc0ttRTJtRFlmMGE4cnQxa2Q0WE54VTNnM05BSGlGdVExMkJicWszTlBHRE0tNk4xUDBhQU1EMVY4Zm8ySVNfa0pIbDVockhiUzBjLWs0YnZiRlJPRkFaV3BvUFc1T0t1VWR3RFV1VW1KNV9xdGdZOEYtYw&q=https%3A%2F%2Fwww.csoonline.com%2Farticle%2F3562701%2Fchinese-researchers-break-rsa-encryption-with-a-quantum-computer.html&v=_iSih4KI_qQ)
    * [x] 4096 bit Fails on 5.7.1 Yubikey
    * [ ] Test 3072 bit RSA
    * [ ] Test ECDSA keys
      * [ ] Create hybrid scheme fallback and use dbx revocations
* [ ] Setup Secure Bootflow
  * [ ] U-Boot Secure boot with verified FIT -> TF-A -> Default: run bootcmd -> UEFI Secure Boot
    * [ ] Change default run to efiload
    * [ ] Enable stack protection
    * [ ] Block dropping down to shell
* [x] Generate SBOM at buildtime
  * [x] Scan with Grype
* [x] Fine tune for reproducibility
  * [x] Convert to docker build
    * [x] Build variants in one branch
    * [x] Make reproducible debian docker images

## Build Instructions/Usage:

### Build:

```
buildscript.sh
 -c {Clean: yes/no}
 -d {Date: source_date_epoch}
 -r {Release-tag: tagname}
 -t {Test-mode: yes/no}
```

To build current release run:

```
sudo su && \
git clone git@github.com:0mniteck/U-Boot.git && \
cd U-Boot && \
./buildscript.sh -r "tagname"
```

To build for reproducibility run:

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

--> [FLASHING](https://github.com/0mniteck/U-Boot/blob/Docs/docs/FLASH.md)

--> [SIGNING YOUR OWN](https://github.com/0mniteck/U-Boot/blob/Docs/docs/SIGN.md)
