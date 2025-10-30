# U-Boot RockChip <sup><sub>- rk3399 (HARDENING), & rk3588 (TESTING)</sub></sup>

### Project Goals:
* [ ] Enable vTPM Support
  * [ ] Test TPM2_FTPM_TEE
    * [x] Build StandaloneMM
      * [x] Migrate from old branch
    * [x] Build ms-tpm-20-ref
      * [x] Openssl use source include current upstream
        * [x] Set OPENSSL_API_COMPAT 10100
      * [ ] Update optee_ftpm/sub.mk to support v1.83
    * [ ] TPM_PCR_ALLOCATE
    * [ ] MEASURED_BOOT
  * [ ] Check if [new patches](https://github.com/radxa-pkg/radxa-overlays/pull/385) fixed problem
* [x] Remove rkbin dependency from rk3568 & rk3588
  * [x] TF-A/Optee-OS upstreamed initial patches from rockchip
  * [x] U-boot modifications to use u-boot-tpl vs rockchip-tpl
  * [x] Resolve rk3588 issues - Enable TPL in Kconfig
  * [ ] Resolve rk3568 issues - SPL_MAX
* [x] Enable Self Signing of UEFI Secure Boot with Root CA only on a Yubikey
  * [ ] Use-once model for next secure boot signing (Reset Yubikey after initial signing)
    * [ ] 2025 Q4 signing
      * [ ] Debian from trixie ISO shimaa64efi/bootaa64.efi
      * [ ] Ubuntu from 25.10 ISO shimaa64.efi/bootaa64.efi
        * [ ] Update autoinstall to plucky release
  * [ ] Try higher bit RSA/ECDSA keys to protect against [Quantum Attacks](https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqbENJQmx3b3pWV2F0YU9tMG8yRGxTb1c1cElQUXxBQ3Jtc0ttRTJtRFlmMGE4cnQxa2Q0WE54VTNnM05BSGlGdVExMkJicWszTlBHRE0tNk4xUDBhQU1EMVY4Zm8ySVNfa0pIbDVockhiUzBjLWs0YnZiRlJPRkFaV3BvUFc1T0t1VWR3RFV1VW1KNV9xdGdZOEYtYw&q=https%3A%2F%2Fwww.csoonline.com%2Farticle%2F3562701%2Fchinese-researchers-break-rsa-encryption-with-a-quantum-computer.html&v=_iSih4KI_qQ)
    * [x] 4096 bit Fails on 5.7.1 Yubikey
    * [ ] Test 3072 bit RSA
    * [ ] Test ECDSA verification
* [ ] Sign FIT images and enable COT (Chain of Trust) in ATF
  * [x] Enable COT
  * [ ] Sign rotprivk to replace dev certs
* [ ] [Setup Secure Bootflow](https://labs.withsecure.com/content/dam/labs/docs/2020-05-u-booting-securely-wp-final.pdf)
  * [ ] U-Boot Secure boot with verified FIT -> TF-A -> Default: run bootcmd -> UEFI Secure Boot
    * [x] Protect against untrusted environment variables
    * [x] Restrict to BOOTM
      * [x] Remove BOOTDEV_*
    * [x] Change BOOTCMD to `efiload; reset;`
    * [x] Enable STACKPROTECTOR
    * [ ] DISABLE_CONSOLE
* [x] Add local docker build-cache 
* [x] Generate SBOM at buildtime
  * [x] Scan with Grype
  * [x] Display Status
* [x] Fine tune for reproducibility and ephemerality
  * [x] Always erase & flash from ring-0
  * [x] Convert to docker build
    * [x] Build variants in one branch
    * [x] Make reproducible debian docker images

## 

### [Docs:](https://github.com/0mniteck/U-Boot/tree/Docs/docs)

--> [BUILD INSTRUCTIONS](https://github.com/0mniteck/U-Boot/blob/Docs/docs/BUILD.md)

--> [FLASHING AND INSTALLING](https://github.com/0mniteck/U-Boot/blob/Docs/docs/FLASH.md)  --> [FLASHING DEMO](https://u-boot.omniteck.com/#content)

--> [SIGNING YOUR OWN](https://github.com/0mniteck/U-Boot/blob/Docs/docs/SIGN.md)

--> [The Sovereignty Ephemerality Reproducibility (SER) framework](https://omniteck.com/?p=1104)
