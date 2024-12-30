#!/bin/sh
set -e

READLINK="readlink"

case "$(uname -s)" in
    Darwin)
        NATIVE_LINKER=ld64.lld
        ;;
    *)
        NATIVE_LINKER=ld.lld
        ;;
esac

BREW_PREFIX_LLVM=${BREW_PREFIX_LLVM:-$(brew --prefix llvm)}
BREW_PREFIX_LLD=${BREW_PREFIX_LLD:-$(brew --prefix lld)}
BREW_PREFIX_PKGCONF=${BREW_PREFIX_PKGCONF:-$(brew --prefix pkgconf)}

DEBIAN_MIRROR=${DEBIAN_MIRROR:-http://ftp.nl.debian.org/debian/pool/main}
FREEBSD_MIRROR=${FREEBSD_MIRROR:-https://download.freebsd.org}


CACHE_DIR=cache

. functions

ksysroot_native() {
    local target_dir="$1"
    local target_dir_abs
    target_dir_abs="$(${READLINK} -f "${target_dir}")"

    mk_wrappers native "${target_dir_abs}" "N/A" "${NATIVE_LINKER}"
    emit_meta_env native "${target_dir_abs}" > "${target_dir}"/bin/native-env
    chmod +x "${target_dir}"/bin/native-env
    emit_meta_llvm native "${target_dir_abs}" "${NATIVE_LINKER}" > "${target_dir}"/native.txt
}

. functions-native
. functions-debian
. functions-freebsd

ksysroot_test() {
    local ksysroot_dir="$1"

    local MESON_SETUP="--native-file=${ksysroot_dir}/native.txt"
    if [ -e "${ksysroot_dir}/cross.txt" ]; then
        MESON_SETUP="${MESON_SETUP} --cross-file=${ksysroot_dir}/cross.txt"
    fi

    local build_dir
    for i in c cxx; do
        build_dir="build-$1-${i}"
        rm -rf "${build_dir}"
        # shellcheck disable=SC2086
        meson setup ${MESON_SETUP} "${build_dir}" test-"${i}" && meson compile -C "${build_dir}"
    done
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

#     testall)
#         test_all
#         ;;
#     install)
#         install_sysroot "${2:-$(${MKTEMP} -dt ksysroot-)}" "${3:-native}"
#         ;;
#     *)

usage() {
        echo Usage:
        echo     "$0" bom triple
        echo     "$0" frombom triple target-directory \< bomfile
        echo     "$0" install triple target-directory
        echo     "$0" test directory
}

dispatch() {
    local cmd="$1"
    shift
    case "${cmd}" in
        test)
            ksysroot_test "$1"
            ;;
        *)
            case "$1" in
                *linux*-gnu|*@debian*)
                    ksysroot_debian_"${cmd}" "$@"
                    ;;
                *freebsd*)
                    ksysroot_freebsd_"${cmd}" "$@"
                    ;;
                native)
                    ksysroot_native_"${cmd}" "$@"
                    ;;
                *)
                    usage
                    return 1                
            esac
            ;;
    esac
}

dispatch "$@"