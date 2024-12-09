#!/bin/sh
set -e

CURL=curl
MKTEMP=mktemp
READLINK=readlink
TAR=tar

BREW_PREFIX_LLVM=${BREW_PREFIX_LLVM:-$(brew --prefix llvm)}
BREW_PREFIX_LLD=${BREW_PREFIX_LLD:-$(brew --prefix lld)}
BREW_PREFIX_PKGCONF=${BREW_PREFIX_PKGCONF:-$(brew --prefix pkgconf)}

DEBIAN_MIRROR=${DEBIAN_MIRROR:-http://ftp.nl.debian.org/debian/pool/main}
FREEBSD_MIRROR=${FREEBSD_MIRROR:-https://download.freebsd.org}


CACHE_DIR=cache

# environment definition for legacy tooling
# we use the wrappers
emit_meta_env() {
    local triple="$1"
    local sysroot="$2"

    cat <<EOF
LLVM_DIR=${BREW_PREFIX_LLVM}
LLD_DIR=${BREW_PREFIX_LLD}

LLVM_CONFIG=\${LLVM_DIR}/bin/llvm-config
PKG_CONFIG=${sysroot}/bin/${triple}-pkg-config

CC=${sysroot}/bin/${triple}-cc
CXX=${sysroot}/bin/${triple}-c++

AR=\${LLVM_DIR}/bin/llvm-ar
AS=\${LLVM_DIR}/bin/llvm-as
CPP=${sysroot}/bin/${triple}-cpp
LD=${sysroot}/bin/${triple}-ld
NM=\${LLVM_DIR}/bin/llvm-nm
OBJCOPY=\${LLVM_DIR}/bin/llvm-objcopy
OBJDUMP=\${LLVM_DIR}/bin/llvm-objdump
RANLIB=\${LLVM_DIR}/bin/llvm-ranlib
READELF=\${LLVM_DIR}/bin/llvm-readelf
SIZE=\${LLVM_DIR}/bin/llvm-size
STRINGS=\${LLVM_DIR}/bin/llvm-strings
STRIP=\${LLVM_DIR}/bin/llvm-strip
EOF
}

# emit cross pkg-config personality
emit_meta_pc() {
    local triple="$1"
    local sysroot="$2"
    cat <<EOF
Triplet: ${triple}
SysrootDir: ${sysroot}
DefaultSearchPaths: ${sysroot}/usr/local/libdata/pkgconfig:${sysroot}/usr/libdata/pkgconfig
SystemIncludePaths: ${sysroot}/usr/include
SystemLibraryPaths: ${sysroot}/usr/lib
EOF
}

# emit generic meson cross/native files
# useful Meson constants:
#   sysroot -- our sysroot
#   triple  -- our triple
#   BREW_PREFIX_LLVM_${name} - directory to llvm
# With Meson we don't need to use the wrappers! 
emit_meta_llvm() {
    local name="$1"
    local ksysroot_dir="$2"
    local ld="$3"

    local pkg_config=

    if [ ${name} == "native" ]; then
        pkg_config="'${BREW_PREFIX_PKGCONF}/bin/pkg-config'"
    else
        pkg_config="ksysroot_dir_${name} / 'bin' / triple+'-pkg-config'"
    fi

    cat <<EOF
[binaries]
llvm-config = llvm_dir_${name} / 'bin/llvm-config'
pkg-config = ${pkg_config}

c = llvm_dir_${name} / 'bin/clang'
c_ld = lld_dir_${name} / 'bin/${ld}'
cpp = llvm_dir_${name} / 'bin/clang++'
cpp_ld = lld_dir_${name} / 'bin/${ld}'

ar = llvm_dir_${name} / 'bin/llvm-ar'
as = llvm_dir_${name} / 'bin/llvm-as'
ld = lld_dir_${name} / 'bin/${ld}'
nm = llvm_dir_${name} / 'bin/llvm-nm'
objcopy = llvm_dir_${name} / 'bin/llvm-objcopy'
objdump = llvm_dir_${name} / 'bin/llvm-objdump'
ranlib = llvm_dir_${name} / 'bin/llvm-ranlib'
readelf = llvm_dir_${name} / 'bin/llvm-readelf'
size = llvm_dir_${name} / 'bin/llvm-size'
strings = llvm_dir_${name} / 'bin/llvm-strings'
strip = llvm_dir_${name} / 'bin/llvm-strip'

[constants]
llvm_dir_${name} = '${BREW_PREFIX_LLVM}'
lld_dir_${name} = '${BREW_PREFIX_LLD}'
ksysroot_dir_${name} = '${ksysroot_dir}'
EOF
}

# emit meson cross files (complete with generic part)
emit_meta_llvm_cross() {
    local name=$1
    local triple="$2"
    local target_dir_abs="$3"
    local sysroot="$4"
    local ld="$5"
    local meson_system="$6"
    local meson_cpufamily="$7"
    local meson_cpu="$8"
    local meson_endian="$9"

    emit_meta_llvm ${name} ${target_dir_abs} ${ld}

    cat <<EOF
triple = '${triple}'
sysroot = '${sysroot}'
common_args = ['-target', '${triple}', '--sysroot=' + sysroot]

[properties]
needs_exe_wrapper = true
sys_root = sysroot

[host_machine]
system = '${meson_system}'
cpu_family = '${meson_cpufamily}'
cpu = '${meson_cpu}'
endian = '${meson_endian}'

[built-in options]
c_args = common_args
cpp_args = common_args
c_link_args = common_args
EOF
}

# create a wrapper with additional prepended arguments
# if no arguments are given, a symlink will do
mk_wrapper() {
    local tgt_file="$1"
    shift
    if [ $# -eq 1 ]; then
        ln -s "$1" "${tgt_file}"
    else
        cat >${tgt_file} <<EOF
#!/bin/sh
exec $@ "\$@"
EOF
        chmod +x ${tgt_file}
    fi
}

# create wrappers for legacy uses
mk_wrappers() {
    local triple="$1"
    local target_dir_abs="$2"
    local sysroot="$3"
    local ld="$4"

    mkdir -p ${target_dir_abs}/bin
    local sysroot_args=
    local common_args=
    local pkgconf_args=

    if [ ${triple} != "native" ]; then
        sysroot_args="--sysroot=${sysroot}"
        common_args="-target ${triple} ${sysroot_args}"
        pkgconf_args="--personality=${target_dir_abs}/pkg-config.personality"
    fi
    mk_wrapper ${target_dir_abs}/bin/${triple}-pkg-config ${BREW_PREFIX_PKGCONF}/bin/pkg-config ${pkgconf_args}
    mk_wrapper ${target_dir_abs}/bin/${triple}-cc ${BREW_PREFIX_LLVM}/bin/clang ${common_args} -fuse-ld=${BREW_PREFIX_LLD}/${ld}
    mk_wrapper ${target_dir_abs}/bin/${triple}-c++ ${BREW_PREFIX_LLVM}/bin/clang++ ${common_args} -fuse-ld=${BREW_PREFIX_LLD}/${ld}
    mk_wrapper ${target_dir_abs}/bin/${triple}-cpp ${BREW_PREFIX_LLVM}/bin/clang-cpp ${common_args}
    mk_wrapper ${target_dir_abs}/bin/${triple}-ld ${BREW_PREFIX_LLD}/bin/${ld} ${sysroot_args}
}

cache() {
    local url="$1"
    local base="${2:-$(basename ${url})}"
    local cache_file="${CACHE_DIR}/${base}"
    test -f "${cache_file}" || ${CURL} --fail -o "${cache_file}" "${url}"
    echo ${cache_file}
}
# unpack the Debian archive passed in $2 into existing directory $1 
# stripping $3 number directory prefix components
undeb() {
    local target="$1"
    local debfile="$2"
    local strip="$3"
	${TAR} -Oxzf "${debfile}" data.tar.xz  | ${TAR} -C "${target}" -xz --strip-components=${strip}
}


debian_list() {
    local version="$1"
    local triple="$2"

    local libc_cross_version
    local libgcc_cross_version
    local linux_version

    case "${triple}" in 
        aarch64-linux-gnu)
            arch=arm64
            ;;
        i686-linux-gnu)
            arch=i386
            ;;
        powerpc64-linux-gnu)
            arch=ppc64
            ;;
        x86_64-linux-gnu)
            arch=amd64
            ;;
        *)
            arch=${triple%-*-*}
            ;;
    esac
    case "${version}" in
        12)
            libc_cross_version=2.36-8cross1
            libgcc_cross_version=12.2.0-14cross1
            linux_version=6.1.4-1cross1
            ;;
        13)
            libc_cross_version=2.40-3cross1
            libgcc_cross_version=14.2.0-6cross1
            linux_version=6.11.2-1cross1
            ;;
        *)
            echo Unknown version
            return 1
            ;;
    esac      
    local libgcc_cross_major="${libgcc_cross_version%.*.*}"

    echo ${DEBIAN_MIRROR}/c/cross-toolchain-base/libc6-${arch}-cross_${libc_cross_version}_all.deb
    echo ${DEBIAN_MIRROR}/c/cross-toolchain-base/libc6-dev-${arch}-cross_${libc_cross_version}_all.deb
    echo ${DEBIAN_MIRROR}/c/cross-toolchain-base/linux-libc-dev-${arch}-cross_${linux_version}_all.deb
    echo ${DEBIAN_MIRROR}/g/gcc-${libgcc_cross_major}-cross/libgcc-s1-${arch}-cross_${libgcc_cross_version}_all.deb
    echo ${DEBIAN_MIRROR}/g/gcc-${libgcc_cross_major}-cross/libgcc-${libgcc_cross_major}-dev-${arch}-cross_${libgcc_cross_version}_all.deb
    return 0
}

ksysroot_native() {
    local target_dir="$1"
    local target_dir_abs="$(${READLINK} -f ${target_dir})"

    mk_wrappers native ${target_dir_abs} "N/A" ld64.lld
    emit_meta_env native ${target_dir_abs} > ${target_dir}/env
    emit_meta_llvm native ${target_dir_abs} ld64.lld > ${target_dir}/native.txt
}

ksysroot_debian() {
    local version="${1#debian}"
    local triple="$2"
    local target_dir="${3:-ksysroot-$2}"
    local target_dir_abs="$(${READLINK} -f ${target_dir})"

# FIXME: cpu_family, cpu, endian
    local meson_cpufamily="${triple%-*-*}"
    local meson_cpu="${triple%-*-*}"
    local meson_endian="little"

    for i in $(debian_list ${version} ${triple}); do
        echo Need $i
        local deb_file=$(cache $i)
        case "$i" in
        *libgcc-*-dev*)
            undeb ${target_dir} ${deb_file} 2
            ;;
        *)
            undeb ${target_dir} ${deb_file} 3
            ;;
        esac
    done  

    mv -i ${target_dir}/share/doc/* ${target_dir}/share/doc
    mv -i ${target_dir}/share/lintian/overrides/* ${target_dir}/lintian/overrides
    rm ${target_dir}/share/doc/*
    rmdir ${target_dir}/share/doc
    for i in lintian; do
        rmdir ${target_dir}/share/$i/* ${target_dir}/share/$i 
    done
    rmdir ${target_dir}/share
    mkdir -p ${target_dir}/usr/${triple}
    ln -s ../../lib ${target_dir}/usr/${triple}/lib
    test -d ${target_dir}/lib64 && ln -s ../../lib64 ${target_dir}/usr/${triple}/lib64

    mk_wrappers ${triple} ${target_dir_abs} ${target_dir_abs}/cross ld.lld 
    emit_meta_env ${triple} ${target_dir_abs} > ${target_dir}/env
    emit_meta_pc ${triple} ${target_dir_abs} > ${target_dir}/pkg-config.personality
    emit_meta_llvm native ${target_dir_abs} ld64.lld > ${target_dir}/native.txt
    emit_meta_llvm_cross cross ${triple} ${target_dir_abs} ld.lld linux ${meson_cpufamily} ${meson_cpu} ${meson_endian} > ${target_dir}/cross.txt
}

ksysroot_freebsd() {
    local version="${1#freebsd}"
    local triple="$2"
    local target_dir="${3:-ksysroot-$2}"
    local target_dir_abs="$(${READLINK} -f ${target_dir})"

    local machine
    local machine_cpuarch
    local machine_arch
    local meson_cpufamily
    local meson_cpu
    local meson_endian

    case "${triple}" in
        aarch64*)
            machine=arm64
            machine_cpuarch=aarch64
            machine_arch=aarch64
            meson_cpufamily="aarch64"
            ;;
        armv7*)
            machine=arm
            machine_cpuarch=arm
            machine_arch=armv7
            meson_cpufamily="arm"
            ;;
        i386*)
            machine=i386
            machine_cpuarch=i386
            machine_arch=i386
            meson_cpufamily="x86"
            ;;
        powerpc-*)
            machine=powerpc
            machine_cpuarch=powerpc
            machine_arch=powerpc
            meson_cpufamily="ppc"
            ;;
        powerpcspe-*)
            machine=powerpc
            machine_cpuarch=powerpc
            machine_arch=powerpcspe
            meson_cpufamily="ppc"
            ;;
        powerpc64-*)
            machine=powerpc
            machine_cpuarch=powerpc
            machine_arch=powerpc64
            meson_cpufamily="ppc64"
            ;;
        powerpc64le-*)
            machine=powerpc
            machine_cpuarch=powerpc
            machine_arch=powerpc64le
            meson_cpufamily="ppc64"
            ;;
        riscv64-*)
            machine=riscv
            machine_cpuarch=riscv
            machine_arch=riscv64
            meson_cpufamily="riscv64"
            ;;
        amd64*|x86_64*)
            machine=amd64
            machine_cpuarch=amd64
            machine_arch=amd64
            meson_cpufamily="x86_64"
            ;;
        *)
            echo Unknown machine ${triple}
            return 1
            ;;
    esac
    meson_cpu=${meson_cpufamily}
    meson_endian=${meson_endian:-little}

    echo provided base as ..${BASE_TXZ}..
    local base_file=
    if [ "x${BASE_TXZ}" = "x" ]; then
        local freebsd_base_url
        case "${version}" in
            *-RELEASE|*-RC?|*-BETA?)
                freebsd_base_url=${FREEBSD_MIRROR}/releases
                ;;
            *-STABLE|*-CURRENT)
                freebsd_base_url=${FREEBSD_MIRROR}/snapshots
                ;;       
            *)
                echo Unknown version ${version}
                return 1
                ;;
        esac
        base_file=$(cache ${freebsd_base_url}/${machine}/${machine_arch}/${version}/base.txz ${machine}_${machine_arch}_freebsd${version}-base.txz)
    else
        base_file=${BASE_TXZ}
    fi

    mkdir "${target_dir}/cross"
    ${TAR} -C "${target_dir}/cross" -xf ${base_file} ./lib ./usr/lib ./usr/include ./usr/libdata/pkgconfig/


    mk_wrappers ${triple} ${target_dir_abs} ${target_dir_abs}/cross ld.lld
    emit_meta_env ${triple} ${target_dir_abs}/cross > ${target_dir}/env
    emit_meta_pc ${triple} ${target_dir_abs}/cross > ${target_dir}/pkg-config.personality

    emit_meta_llvm native ${target_dir_abs} ld64.lld > ${target_dir}/native.txt
    emit_meta_llvm_cross cross ${triple} ${target_dir_abs} ${target_dir_abs}/cross ld.lld  freebsd ${meson_cpufamily} ${meson_cpu} ${meson_endian} > ${target_dir}/cross.txt
    cat >> ${target_dir}/cross.txt <<EOF
pkg_config_path = sysroot / 'usr/local/libdata/pkgconfig' + ':' + sysroot / 'usr/libdata/pkgconfig'
EOF
    return 0
}

ksysroot_freebsd_pkgbase() {
	# FreeBSD-clibs-dev FreeBSD-clibs FreeBSD-libcompiler_rt-dev
    echo FIXME: implement
    return 1
}

install_sysroot() {
    local ksysroot_dir="$1"
    local ksysroot="$2"

    local triple="${ksysroot%@*}"
    local flavour="${ksysroot#*@}"
    echo Creating ksysroot ${ksysroot_dir} for triple ${triple} and flavour ${flavour} 
    mkdir -p "${ksysroot_dir}"
    case "${flavour}" in
        native)
            ksysroot_native ${ksysroot_dir}
            ;;
        debian*)
            ksysroot_debian ${flavour} ${triple} ${ksysroot_dir}
            ;;
        freebsd*)
            ksysroot_freebsd ${flavour} ${triple} ${ksysroot_dir}
            ;;
        *)
            echo Unknown flavour ${flavour}
            return 1
            ;;
    esac

}

test_sysroot() {
    local ksysroot_dir="ksysroot-$1"
    test -d "${ksysroot_dir}" || install_sysroot ${ksysroot_dir} $1

    local build_dir="build-$1"
    rm -rf ${build_dir}

    case "$1" in
        native)
            meson setup --native-file=${ksysroot_dir}/native.txt ${build_dir} test-c && meson compile -C ${build_dir}
            ;;
        *)
            meson setup --native-file=${ksysroot_dir}/native.txt --cross-file=${ksysroot_dir}/cross.txt ${build_dir} test-c && meson compile -C ${build_dir}
            ;;
    esac
}

test_all() {
    test_sysroot native

    # fix backports with Debian
    # armel-linux-gnu
    # mips64-linux-gnu
    # powerpc64-linux-gnu
    # riscv64-linux-gnu
    # mips64-linux-gnu

    # add from Alpine or OpenWRT
    # x86_64-linux-musl
    # arm-linux-musleabi 
    # arm-linux-musleabihf
    # for triple in aarch64-linux-gnu i686-linux-gnu x86_64-linux-gnu; do
    #     for version in 12 13; do
    #         test_sysroot ${triple}@debian${version}
    #     done
    # done

    for triple in aarch64-freebsd x86_64-freebsd i386-freebsd; do
    # for triple in x86_64-freebsd; do
        for version in 15.0-CURRENT 14.2-RELEASE 14.1-RELEASE 13.4-RELEASE 13.3-RELEASE; do
            test_sysroot ${triple}${version%.*}@freebsd${version}
        done
    done
}

case "$1" in
    test)
        test_sysroot "${2:-native}"
        ;;
    testall)
        test_all
        ;;
    install)
        install_sysroot "${2:-$(${MKTEMP} -dt ksysroot-)}" "${3:-native}"
        ;;
    *)
        echo Usage:
        echo     $0 test {triple}
        echo     $0 install {target_dir} {triple}
        exit 1
        ;;
esac


