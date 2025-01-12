# `ksysroot` - create sysroots for cross compilation
`ksysroot` is a collection of POSIX shell scripts that automates the creation of sysroot directories for use in cross compilation.

It conveniently downloads, extracts directly from original installation media (e.g. DEB archives) and creates wrapper functions for ease of use with other tools, e.g. [The Meson Build System](https://mesonbuild.com/).

Besides the standard build tools (e.g. `cc`), `ksysroot` also cater for a proper cross `pkg-config`.

`ksysroot` will add known quirks to the wrapper functions to invoke the toolchain properly.

Except for fixing symbolic links, `no alterations` are performed on the downloaded original distribution binaries.

`ksysroot` is  tool for developers. If you would like to have the convenience of pre-packaged ready to use sysroots, take a look at 
[homebrew-ksysroot](https://github.com/kevemueller/homebrew-ksysroot)

## Usage

### Create sysroot

```sh
% rm -rf my-cross
% ./ksysroot.sh install aarch64-linux-gnu my-cross

% my-cross/bin/aarch64-linux6.1-gnu-cc --version
Homebrew clang version 19.1.6
Target: aarch64-unknown-linux6.1-gnu
Thread model: posix
InstalledDir: /usr/local/Cellar/llvm/19.1.6/bin

% my-cross/bin/aarch64-linux6.1-gnu-pkg-config --list-all
libnsl                         libnsl - Library containing NIS functions using TI-RPC (IPv6 enabled)
libxcrypt                      libxcrypt - Extended crypt library for DES, MD5, Blowfish and others
libcrypt                       libxcrypt - Extended crypt library for DES, MD5, Blowfish and others
libtirpc                       libtirpc - Transport Independent RPC Library
```

Adding additional packages
```sh
% rm -rf my-cross
% KSYSROOT_ADD_PKG="libcurl4-openssl-dev" ./ksysroot.sh install aarch64-linux-gnu my-cross

% my-cross/bin/aarch64-linux6.1-gnu-pkg-config --list-all
libnsl                         libnsl - Library containing NIS functions using TI-RPC (IPv6 enabled)
libxcrypt                      libxcrypt - Extended crypt library for DES, MD5, Blowfish and others
libcurl                        libcurl - Library to transfer files with ftp, http, etc.
libcrypt                       libxcrypt - Extended crypt library for DES, MD5, Blowfish and others
libtirpc                       libtirpc - Transport Independent RPC Library
```

### Test sysroot
```sh
% rm -rf my-cross
% ./ksysroot.sh install aarch64-linux-gnu my-cross
% ./ksysroot.sh test my-cross

% file build-my-cross-c/main
build-my-cross-c/main: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, with debug_info, not stripped
```

### Use with meson
```sh
% rm -rf my-cross
% ./ksysroot.sh install aarch64-linux-gnu my-cross
% meson setup --cross-file=my-cross/cross.txt --native-file=my-cross/native.txt my-cross-build my-source
```

### Use with legacy tooling
```sh
% rm -rf my-cross
% my-cross/bin/aarch64-linux6.1-gnu-env make all
```

### Advanced usage
Create a bill of materials, i.e. all distribution binaries needed to create the sysroot and create the sysroot from the bill of materials definition.
The bom contains the metadata, e.g. triples, meson constants as well as every binary, listing
* package-name
* package-version
* download-url
* preferred-filename
* SHA-256 checksum

```sh
% ./ksysroot.sh bom s390x-linux-gnu@debian13 > my-bom
% cat my-bom
# KSYSROOT_TRIPLE=s390x-linux-gnu KSYSROOT_FULL_TRIPLE=s390x-linux6.12-gnu
# KSYSROOT_OSFLAVOUR=debian KSYSROOT_OSRELEASE=13
# KSYSROOT_LINKER=ld.lld
# KSYSROOT_LICENSE=GPL-2.0-or-later
# MESON_SYSTEM=linux MESON_CPUFAMILY=s390x MESON_CPU=s390x MESON_ENDIAN=big
# DEBIAN_VERSION=13 DEBIAN_NAME=trixie DEBIAN_GCC=14
# DEBIAN_ARCH=s390x LINUX_VERSION=6.12
gcc-14-base 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/gcc-14-base_14.2.0-12_s390x.deb debian/gcc-14-base_14.2.0-12_s390x.deb cb6a26695bbfd029e57d3b58579742b94e4a3ef94ae6d6dc746ccb1aae8fa321
libasan8 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libasan8_14.2.0-12_s390x.deb debian/libasan8_14.2.0-12_s390x.deb cfd601465993e989fd2d6c7333b4b15a7edf048e4f680ea544bbd79ed3d8b5f6
libatomic1 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libatomic1_14.2.0-12_s390x.deb debian/libatomic1_14.2.0-12_s390x.deb 472225ff7721aa61db35e54f27b449a793cebbd338b0263a95adbaee30b3f462
libc-dev-bin 2.40-4 http://deb.debian.org/debian/pool/main/g/glibc/libc-dev-bin_2.40-4_s390x.deb debian/libc-dev-bin_2.40-4_s390x.deb 657a7aa6e134606595b57b692ef03adfb248cd85b1a0f6857ffcc36ad3cc9e8a
libc6 2.40-4 http://deb.debian.org/debian/pool/main/g/glibc/libc6_2.40-4_s390x.deb debian/libc6_2.40-4_s390x.deb ae66a8192cb3f09ad71b9c2156e8502430e28292cd4893f282b68f4476afc6c8
libc6-dev 2.40-4 http://deb.debian.org/debian/pool/main/g/glibc/libc6-dev_2.40-4_s390x.deb debian/libc6-dev_2.40-4_s390x.deb 8c3febfca93f43095d78cc89cf55107687f4c1639f771d78c21ebee1e9fda093
libcrypt-dev 1:4.4.36-5 http://deb.debian.org/debian/pool/main/libx/libxcrypt/libcrypt-dev_4.4.36-5_s390x.deb debian/libcrypt-dev_1%3a4.4.36-5_s390x.deb aef67f6821c89715bfaeec3013e70ae4d0ca4c091a705ade5ee3a4134ec12d42
libcrypt1 1:4.4.36-5 http://deb.debian.org/debian/pool/main/libx/libxcrypt/libcrypt1_4.4.36-5_s390x.deb debian/libcrypt1_1%3a4.4.36-5_s390x.deb 2640220bf7207223086874a2d7c672c50bd977550add313a1afdbe996b8e2c4e
libgcc-14-dev 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libgcc-14-dev_14.2.0-12_s390x.deb debian/libgcc-14-dev_14.2.0-12_s390x.deb 80c4994fa70828ddde0cb5f50ea9d1779d96c30b9b73f862353a578428a569e1
libgcc-s1 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libgcc-s1_14.2.0-12_s390x.deb debian/libgcc-s1_14.2.0-12_s390x.deb 6e62ab83b6f0f6c0cdbd2926ccdbb523e13fd023ed4ed1e976150ee61e16c5a5
libgomp1 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libgomp1_14.2.0-12_s390x.deb debian/libgomp1_14.2.0-12_s390x.deb 862fa620340aa921808e7c1d7ca45606bd312c17208d35adb0522083f71d26cc
libitm1 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libitm1_14.2.0-12_s390x.deb debian/libitm1_14.2.0-12_s390x.deb fbe93d63a23a58388245ebeac10e2ea72d15de9e1a01b66a1702125b09dc0871
libstdc++-14-dev 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libstdc++-14-dev_14.2.0-12_s390x.deb debian/libstdc++-14-dev_14.2.0-12_s390x.deb 72f9d26e7e0e180d37b9f2b278727ea554e601e06a601d8d731fd9c388917eee
libstdc++6 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libstdc++6_14.2.0-12_s390x.deb debian/libstdc++6_14.2.0-12_s390x.deb cc701773db37aea6adbaf36ce2f05e1118b4d0e2d6b69d48e4f9c021a1855a92
libubsan1 14.2.0-12 http://deb.debian.org/debian/pool/main/g/gcc-14/libubsan1_14.2.0-12_s390x.deb debian/libubsan1_14.2.0-12_s390x.deb c32811497d4bc778a51ee053fa3f0e08021bc981327e37ba64c6287edb636134
linux-libc-dev 6.12.6-1 http://deb.debian.org/debian/pool/main/l/linux/linux-libc-dev_6.12.6-1_all.deb debian/linux-libc-dev_6.12.6-1_all.deb 4bf6702ef24dec9cc3ce606d5e9180ac7270a9dca181813a9fa68cfeb31b70ff
rpcsvc-proto 1.4.3-1 http://deb.debian.org/debian/pool/main/r/rpcsvc-proto/rpcsvc-proto_1.4.3-1_s390x.deb debian/rpcsvc-proto_1.4.3-1_s390x.deb 5f63ce83bf1a0d4fa18e5bd098d11e03a21b500e13e30981b15e61af76ca266a
% ./ksysroot.sh frombom my-cross < my-bom
```

## OS support (host/target)

### Debian

`ksysroot` uses `debootstrap` to select the most recent versions of the packages comprising the build system. It has support for the current versions of Debian and all release architectures, namely

| Triple                    | Flavour Bookworm  | Flavour Trixie | Debian Architecture |
| ------------------------- | ----------------- | -------------- | ------------------- |
| x86_64-linux-gnu          | @debian12         | @debian13      | arm64               |
| x86_64-linux-gnu          | @debian12         | @debian13      | amd64               |
| i586-linux-gnu            | @debian12         | @debian13      | i386                |
| mips64el-linux-gnuabi64   | @debian12         | @debian13      | mips64el            |
| powerpc64le-linux-gnu     | @debian12         | @debian13      | ppc64el             |
| arm-linux-gnueabi         | @debian12         |                | armel               |
| arm-linux-gnueabihf       | @debian12         |                | armhf               |
| mipsel-linux-gnu          | @debian12         |                | mipsel              |
| s390x-linux-gnu           | @debian12         |                | s390x               |

Other architectures and Debian versions _may_ work as well.
`ksysroot` currently downloads a minimal environment for C/C++ usage, but can be parameterized to include additional packages.

### Alpine Linux

`ksysroot` uses `apk` to select the most recent versions of the packages comprising the build system. It has support for the current versions of Alpine Linux and all release architectures, namely

| Triple                    | Flavour Branch  | Flavour Edge  | Alpine Architecture |
| ------------------------- | --------------- | ------------- | ------------------- |
| aarch64-linux-musl        | @Alpine-3.21    | @Alpine-edge  | aarch64             |
| armv6-linux-musleabihf    | @Alpine-3.21    | @Alpine-edge  | armhf               |
| armv7-linux-musleabihf    | @Alpine-3.21    | @Alpine-edge  | armv7               |
| loongarch64-linux-musl    | @Alpine-3.21    | @Alpine-edge  | loongarch64         |
| powerpc64le-linux-musl    | @Alpine-3.21    | @Alpine-edge  | ppc64le             |
| riscv64-linux-musl        | @Alpine-3.21    | @Alpine-edge  | riscv64             |
| s390x-linux-musl          | @Alpine-3.21    | @Alpine-edge  | s390x               |
| i586-linux-musl           | @Alpine-3.21    | @Alpine-edge  | x86                 |
| x86_64-linux-musl         | @Alpine-3.21    | @Alpine-edge  | x86_64              |

`ksysroot` currently downloads a minimal environment for C/C++ usage, but can be parameterized to include additional packages. On Alpine the `libstdc++` package is installed for C++.

## FreeBSD
`ksysroot` uses `base.txz` directly from the FreeBSD mirrors to download the files comprising the build. It has support for the current versions of FreeBSD and all released architectures, namely

| Triple                    | Flavour RELEASE      | Flavour STABLE       | Flavour CURRENT      | FreeBSD Architecture |
| ------------------------- | -------------------- | -------------------- | -------------------- | -------------------- |
| aarch64-freebsd15.0       |                      |                      | @freebsd15.0-CURRENT | arm64                |
| aarch64-freebsd14.2       | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | arm64                |
| aarch64-freebsd14.1       | @freebsd14.1-RELEASE |                      |                      | arm64                |
| aarch64-freebsd13.4       | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | arm64                |
| aarch64-freebsd13.3       | @freebsd13.3-RELEASE |                      |                      | arm64                |
| x86_64-freebsd15.0        |                      |                      | @freebsd15.0-CURRENT | amd64                |
| x86_64-freebsd14.2        | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | amd64                |
| x86_64-freebsd14.1        | @freebsd14.1-RELEASE |                      |                      | amd64                |
| x86_64-freebsd13.4        | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | amd64                |
| x86_64-freebsd13.3        | @freebsd13.3-RELEASE |                      |                      | amd64                |
| i686-freebsd15.0          |                      |                      | @freebsd15.0-CURRENT | i386                 |
| i686-freebsd14.2          | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | i386                 |
| i686-freebsd14.1          | @freebsd14.1-RELEASE |                      |                      | i386                 |
| i686-freebsd13.4          | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | i386                 |
| i686-freebsd13.3          | @freebsd13.3-RELEASE |                      |                      | i386                 |
| powerpc-freebsd15.0       |                      |                      | @freebsd15.0-CURRENT | powerpc              |
| powerpc-freebsd14.2       | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | powerpc              |
| powerpc-freebsd14.1       | @freebsd14.1-RELEASE |                      |                      | powerpc              |
| powerpc-freebsd13.4       | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | powerpc              |
| powerpc-freebsd13.3       | @freebsd13.3-RELEASE |                      |                      | powerpc              |
| powerpcspe-freebsd15.0    |                      |                      | @freebsd15.0-CURRENT | powerpcspe           |
| powerpcspe-freebsd14.2    | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | powerpcspe           |
| powerpcspe-freebsd14.1    | @freebsd14.1-RELEASE |                      |                      | powerpcspe           |
| powerpcspe-freebsd13.4    | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | powerpcspe           |
| powerpcspe-freebsd13.3    | @freebsd13.3-RELEASE |                      |                      | powerpcspe           |
| powerpc64-freebsd15.0     |                      |                      | @freebsd15.0-CURRENT | powerpc64            |
| powerpc64-freebsd14.2     | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | powerpc64            |
| powerpc64-freebsd14.1     | @freebsd14.1-RELEASE |                      |                      | powerpc64            |
| powerpc64-freebsd13.4     | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | powerpc64            |
| powerpc64-freebsd13.3     | @freebsd13.3-RELEASE |                      |                      | powerpc64            |
| powerpc64le-freebsd15.0   |                      |                      | @freebsd15.0-CURRENT | powerpc64le          |
| powerpc64le-freebsd14.2   | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | powerpc64le          |
| powerpc64le-freebsd14.1   | @freebsd14.1-RELEASE |                      |                      | powerpc64le          |
| powerpc64le-freebsd13.4   | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | powerpc64le          |
| powerpc64le-freebsd13.3   | @freebsd13.3-RELEASE |                      |                      | powerpc64le          |
| riscv64-freebsd15.0       |                      |                      | @freebsd15.0-CURRENT | riscv64              |
| riscv64-freebsd14.2       | @freebsd14.2-RELEASE | @freebsd14.2-STABLE  |                      | riscv64              |
| riscv64-freebsd14.1       | @freebsd14.1-RELEASE |                      |                      | riscv64              |
| riscv64-freebsd13.4       | @freebsd13.4-RELEASE | @freebsd13.4-STABLE  |                      | riscv64              |
| riscv64-freebsd13.3       | @freebsd13.3-RELEASE |                      |                      | riscv64              |

FreeBSD comes with a rich set of userland libraries which are embedded in the sysroot.
Using FreeBSD `pkg` to download additional packages or using a pkgbase environment is being evaluated.

## NetBSD
`ksysroot` uses `base.tar.xz` and `comp.tar.xz` directly from the NetBSD content delivery system to download the files comprising the build. It has support for the current versions of NetBSD on a few released architectures, namely

| Triple                    | NetBSD Port          |
| ------------------------- | -------------------- |
| aarch64-netbsd10.1        | evbarm-aarch64       |
| aarch64-netbsd10.0        | evbarm-aarch64       |
| x86_64-netbsd10.1         | amd64                |
| x86_64-netbsd10.0         | amd64                |

Additional ports can be trivially added.

## DragonFlyBSD
`ksysroot` uses `dfly-x86_64-<version>_REL.iso.bz2` directly from the DragonFlyBSD content delivery system to download the files comprising the build. It has support for the current version of DragonFlyBSD on a single supported architecture, namely

| Triple                    | DragonFlyBSD arch    |
| ------------------------- | -------------------- |
| x86_64-dragonflybsd6.4    | x86_64               |

Support for _LATEST_ can be trivially added.

## Native
The special `native` triple will create the wrappers that are consistent with the cross target wrappers, but are targeting the build system natively. This is a convenient way to ensure that the same compiler toolchain is used for both native builds as well as cross builds.


## OS support (build)
ksysroot is continuously tested to run under macOS (with brew) and Ubuntu (with brew or apt).
The sysroot works with the `clang` compilation environment.

ksysroot contains a small C program+library and a small C++ program+library that is used to verify the basic functioning of the sysroot.