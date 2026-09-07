# USBNetLite for KPM

USBNetLite provides manually controlled USB networking and Dropbear SSH for
armhf Kindles. This version is packaged for KPM and does not modify the Kindle
root filesystem.

This package targets the
[`kindlehf` toolchain](https://github.com/KindleModding/koxtoolchain#notes),
which supports Kindles running firmware 5.16.3 or later. Hardware and firmware
combinations should still be tested on-device before release.

## Behaviour

- USB networking and SSH are started or stopped manually.
- No Upstart job is installed and USBNetLite does not start at boot.
- The KUAL menu is installed under `/mnt/us/extensions/usbnetlite`.
- Runtime files and persistent settings live under `/mnt/us/usbnetlite`.
- KPM upgrades preserve `etc/config`, `authorized_keys`, and generated host keys.

## Login and configuration

The defaults remain:

```sh
USE_WIFI="true"
PASSWORD_OVERRIDE_ENABLED="true"
PASSWORD="kindle"
ALLOW_PASSWORD_LOGIN="true"
PORT="22"
```

Users can edit `/mnt/us/usbnetlite/etc/config` with KOReader or another text
editor. For example:

```sh
PASSWORD="choose-a-new-password"
```

Stop and start USBNetLite after changing the password. Keep the shell quoting
and do not use whitespace or quote characters inside the password.

The default password is intentionally compatible with the old package, but it
is unsafe on an untrusted Wi-Fi network and should be changed after installation.
The configured password is stored as plain text on the Kindle userstore. For a
safer setup, add a public key to
`/mnt/us/usbnetlite/etc/dropbear/authorized_keys`, then set
`ALLOW_PASSWORD_LOGIN="false"`.

## Manual control

Use the installed KUAL menu, or run:

```sh
/var/local/kmc/bin/kpm launch usbnetlite start
/var/local/kmc/bin/kpm launch usbnetlite stop
/var/local/kmc/bin/kpm launch usbnetlite toggle
/var/local/kmc/bin/kpm launch usbnetlite status
/var/local/kmc/bin/kpm launch usbnetlite enable-wifi
/var/local/kmc/bin/kpm launch usbnetlite disable-wifi
/var/local/kmc/bin/kpm launch usbnetlite restore-config
```

Launching the package without an action toggles USB networking.

## Building

The build requires a Linux environment. On Debian or Ubuntu, install the host
dependencies first:

```sh
sudo apt-get update
sudo apt-get install -y \
    build-essential autoconf automake bison flex gawk git gperf help2man \
    libncurses-dev libtool libtool-bin patch python3 texinfo unzip wget curl file
```

Keep the three repositories next to each other:

```text
kindle-build/
├── KPM/
├── kindle-usbnetlite/
└── koxtoolchain/
```

Create the `kindlehf` cross toolchain once. This may take a while:

```sh
mkdir -p ~/kindle-build
cd ~/kindle-build
git clone https://github.com/KindleModding/koxtoolchain.git
cd koxtoolchain
./gen-tc.sh kindlehf
```

Clone the KPM helper and place this project's KPM branch alongside it:

```sh
cd ~/kindle-build
git clone --depth 1 https://github.com/KindleModding/KPM.git
git clone --recurse-submodules --branch YOUR_KPM_BRANCH YOUR_FORK_URL kindle-usbnetlite
```

Then build the package:

```sh
cd ~/kindle-build/kindle-usbnetlite
./package.sh
```

The build uses:

- the `dropbear` and `openssh` submodules;
- a configured KindleModding `koxtoolchain`;
- `kpm-helper.py` from the KindleModding KPM repository;
- the normal autotools and Python 3 build dependencies.

By default, `package.sh` expects the toolchain at `../koxtoolchain` and the KPM
helper at `../KPM/kpm-helper.py`. Override them when necessary:

```sh
KOX_TOOLCHAIN_ROOT=/path/to/koxtoolchain \
KPM_HELPER=/path/to/KPM/kpm-helper.py \
./package.sh
```

The resulting `usbnetlite_1.0.0_kindlehf.kpkg` is written to `out/`.

Before copying it to a Kindle, verify that the bundled executables are ARM
binaries and inspect the package archive:

```sh
file build/dropbearmulti build/sftp-server
tar -tzf out/usbnetlite_1.0.0_kindlehf.kpkg
sha256sum out/usbnetlite_1.0.0_kindlehf.kpkg
```

`file` should report 32-bit ARM/EABI executables, not x86-64 or AArch64. For a
test before publishing a repository, copy the package to the Kindle userstore
and run:

```text
;kpm install file:///mnt/us/usbnetlite_1.0.0_kindlehf.kpkg
```

Test on a clean device or remove the old MRPI version first. Unplug USB before
using the KUAL start/stop controls.

## Publishing a KPM repository

After producing a real package on Linux, add it to the bundled repository
manifest with:

```sh
./publish-repository.sh out/usbnetlite_1.0.0_kindlehf.kpkg
```

This copies the artifact to
`repository/packages/usbnetlite/artifacts/` and updates
`repository/manifest.v2.json`. Commit and push the entire `repository`
directory to a public HTTPS host. A public GitHub repository can be used
directly through its raw content URL:

```text
https://raw.githubusercontent.com/OWNER/REPOSITORY/BRANCH/repository/manifest.v2.json
```

Users add the source once and install the package with:

```text
;kpm add-repo https://raw.githubusercontent.com/OWNER/REPOSITORY/BRANCH/repository/manifest.v2.json
;kpm update
;kpm install usbnetlite
```

After that, `;kpm install usbnetlite` reinstalls or upgrades USBNetLite, and
`;kpm upgrade` includes it in normal package upgrades. The manifest URL must
point directly to the JSON file, not to the GitHub HTML page. Every published
build must have a new three-part version in `kpm/package/manifest.json`.

If migrating a Kindle that already has the old MRPI package installed, clean up
its `/etc/upstart/usbnetlite*.conf` and `/usr/bin`/`/usr/local/bin` integration
through MRPI or a shell before installing this package. Installation stops when
legacy USBNetLite Upstart jobs are detected. The pure KPM package deliberately
does not alter or clean those rootfs paths itself.
