# `ksysroot` - create sysroots for cross compilation
`ksysroot` is a collection of POSIX shell scripts that automates the creation of sysroot directories for use in cross compilation.

It conveniently downloads, extracts directly from original installation media (e.g. DEB archives) and creates wrapper functions for ease of use with other tools, e.g. meson.build.
Besides the standard build tools (e.g. `cc`), `ksysroot` also cater for a proper cross `pkg-config`.

`ksysroot` is  tool for developers. If you would like to have the convenience of pre-packaged ready to use sysroots, take a look at 
[homebrew-ksysroot](https://github.com/kevemueller/homebrew-ksysroot)

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
`ksysroot` currently downloads a minimal environment for C/C++ usage, but can be trivially extended to include additional packages.

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

## OS support (build)
ksysroot is continuously tested to run under macOS (with brew) and Ubuntu (with brew or apt).
The sysroot works with the `clang` compilation environment.

ksysroot contains a small C program+library and a small C++ program+library that is used to verify the basic functioning of the sysroot.