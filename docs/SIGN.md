# Signing Recipe

### Prerequisites (subject to change)
Debian based systems
1. **YubiKey**: Ensure you have a YubiKey that supports PIV (Personal Identity Verification).
2. **OpenSSL**: Install OpenSSL on your system.
3. **Ykman**: Install the apt version of YubiKey Manager to manage your YubiKey,
   - `apt install ykman`
   - `snap install ykman` can only write to `/tmp/snap-private-tmp/snap.ykman/tmp/`
      - you may need to restart pcscd `sudo service pcscd start`.
5. **Ykcs11**: Install ykcs11 library on your system.
6. **libengine-pkcs11-openssl**: Install pkcs11 libengine dynamic extention on your system.
8. **U-Boot**: Build "mutably" with `CONFIG_HEXDUMP=y` and `CONFIG_CMD_NVEDIT_EFI=y` to make efi vars editable.
9. **sbsign**: Build with slight patch as described in [osresearch/sbsigntools@5154c68](https://github.com/osresearch/sbsigntools/commit/5154c68bce6848b49222564675720d10a1caca2c)
7. **Debuggers**:
   - Install gdb `apt install gdb`
   - Install OpenSC on your system if you need to debug the module further
        - `pkcs11-tools --module /usr/lib/aarch64-linux-gnu/libykcs11.so -t`.

### Steps to Create a Root CA on YubiKey

#### 1. Generate a Key Pair
You can generate a key pair directly on the YubiKey using the YubiKey PIV application. Here’s how to do it:

```
sudo su && pushd /etc/platform/keys/ && ykman piv keys generate -a RSA2048 --touch-policy ALWAYS --pin-policy ALWAYS 9a public_key.pem
```

#### 2. Create a Self-Signed Certificate
Next, you need to create a self-signed certificate using the private key stored on the YubiKey. You can do this with OpenSSL:

```
export PKCS11_MODULE_PATH=/usr/lib/aarch64-linux-gnu/libykcs11.so && openssl x509 -new -engine pkcs11 -keyform ENGINE -key 1 -out ca.pem -subj "/C=US/ST=CA/O=OMNITECK/CN=Root CA" -days 1826
```

#### 3. Import the Certificate to YubiKey
You can import the self-signed certificate back to the YubiKey:

```
ykman piv certificates import -v 9a ca.pem
```

#### 4. Verify the Certificate
You can verify that the certificate is correctly stored on the YubiKey:

```
ykman piv info
```

### Sign Platform Keys

#### 1. Platform Keys

```
openssl req -x509 -sha256 -engine pkcs11 -keyform ENGINE -key 1 -subj /CN=OMNITECK_PK/ -out PK.crt -nodes -days 1826
cert-to-efi-sig-list -g cc1e39bc-7c39-11ef-b26d-9b41b973d7e9 PK.crt PK.esl
sign-efi-sig-list -c PK.crt -t "$(echo $(date +%Y-%m-%d) 00:00:00)" -o PK PK.esl PK.forsig
openssl smime -sign -binary -engine pkcs11 -keyform ENGINE -in PK.forsig -out PK.signed -signer PK.crt -inkey 1 -outform DER -md sha256
sign-efi-sig-list -i PK.signed -t "$(echo $(date +%Y-%m-%d) 00:00:00)" PK PK.esl PK.auth
```

#### 2. Key Exchange Keys

```
openssl req -x509 -sha256 -engine pkcs11 -keyform ENGINE -key 1 -subj /CN=OMNITECK_KEK/ -out KEK.crt -nodes -days 1826
cert-to-efi-sig-list -g cc1e39bc-7c39-11ef-b26d-9b41b973d7e9 KEK.crt KEK.esl
sign-efi-sig-list -c PK.crt -t "$(echo $(date +%Y-%m-%d) 00:00:00)" -o KEK KEK.esl KEK.forsig
openssl smime -sign -binary -engine pkcs11 -keyform ENGINE -in KEK.forsig -out KEK.signed -signer PK.crt -inkey 1 -outform DER -md sha256
sign-efi-sig-list -i KEK.signed -t "$(echo $(date +%Y-%m-%d) 00:00:00)" KEK KEK.esl KEK.auth
```

#### 3. Database Keys

```
openssl req -x509 -sha256 -engine pkcs11 -keyform ENGINE -key 1 -subj /CN=OMNITECK_db/ -out db.crt -nodes -days 1826
cert-to-efi-sig-list -g cc1e39bc-7c39-11ef-b26d-9b41b973d7e9 db.crt db.esl
sign-efi-sig-list -c KEK.crt -t "$(echo $(date +%Y-%m-%d) 00:00:00)" -o db db.esl db.forsig
openssl smime -sign -binary -engine pkcs11 -keyform ENGINE -in db.forsig -out db.signed -signer KEK.crt -inkey 1 -outform DER -md sha256
sign-efi-sig-list -i db.signed -t "$(echo $(date +%Y-%m-%d) 00:00:00)" db db.esl db.auth
```

#### 4. Copy .auth files & sign shimaa64.efi

```
rm -f /boot/efi/*.auth && cp /etc/platform/keys/*.auth /boot/efi/ && rm -f /boot/efi/EFI/ubuntu/shimaa64.efi.signed && sbsign --engine pkcs11 --key 1 --cert db.crt /usr/lib/shim/shimaa64.efi --output /boot/efi/EFI/ubuntu/shimaa64.efi.signed && popd
```

#### 5. Build mutable U-boot & set up secureboot platform keys.

```
# Build U-boot in mutable mode

rm -f /boot/efi/ubootefi.var
reboot

# Stop autoboot and remove any existing entries from eficonfig

eficonfig
reset

# Load platform keys

fatload mmc 0:1 $kernel_addr_r PK.auth
setenv -e -nv -bs -rt -at -i $kernel_addr_r:$filesize PK
fatload mmc 0:1 $kernel_addr_r KEK.auth
setenv -e -nv -bs -rt -at -i $kernel_addr_r:$filesize KEK
fatload mmc 0:1 $kernel_addr_r db.auth
setenv -e -nv -bs -rt -at -i $kernel_addr_r:$filesize db
```

#### 6. Boot to create fresh efi.var store at /boot/efi/ubootefi.var

```
run bootcmd
```

#### 7. Upload to git to bake into build with UEFI Secure Boot enabled.

#### 8. Build immutable U-boot with new efi.vars
