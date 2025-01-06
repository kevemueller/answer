#!/bin/sh
set -e

case "$(uname -s)" in
  Darwin)
    NATIVE_LINKER=ld64.lld
    ;;
  *)
    NATIVE_LINKER=ld.lld
    ;;
esac

: "${KSYSROOT_PREFIX:=$(dirname "$0")}"

. "${KSYSROOT_PREFIX}"/functions

if command -v brew >/dev/null; then
  : "${LLVM_DIR:=$(brew --prefix llvm)/bin}"
  : "${LLD_DIR:=$(brew --prefix lld)/bin}"
  : "${PKG_CONFIG:=$(brew --prefix pkgconf)/bin/pkg-config}"
else
  : "${LLVM_DIR:=$(dirname "$(realpath "$(require_tool clang)")")}"
  : "${LLD_DIR:=$(dirname "$(realpath "$(require_tool lld)")")}"
  : "${PKG_CONFIG:=$(require_tool pkg-config)}"
fi

: "${DEBIAN_MIRROR:=http://ftp.nl.debian.org/debian/pool/main}"
: "${FREEBSD_MIRROR:=https://download.freebsd.org}"

: "${CACHE_DIR:=cache}"

. "${KSYSROOT_PREFIX}"/functions-native
. "${KSYSROOT_PREFIX}"/functions-debian
. "${KSYSROOT_PREFIX}"/functions-freebsd

ksysroot_test_wrapper() {
  local ksysroot_dir="$1"
  local env="${ksysroot_dir}/bin/*-env"

  for i in CC CC_FOR_BUILD CXX CXX_FOR_BUILD CPP CPP_FOR_BUILD LD LD_FOR_BUILD \
    AR AS NM OBJCOPY OBJDUMP RANLIB READELF SIZE STRINGS STRIP; do
    WRAPPER="$(${env} sh -c "echo \${$i}")"
    echo "$i"="${WRAPPER}"
    "${WRAPPER}" --version
    echo
  done
}
ksysroot_test_meson() {
  : "${MESON:=$(require_tool meson)}"
  : "${MESON_SETUP_ARGS:=}"
  : "${MESON_COMPILE_ARGS:=}"

  local ksysroot_dir="$1"
  local base
  base="$(basename "$1")"

  local MESON_SETUP_ARGS="--native-file=${ksysroot_dir}/native.txt ${MESON_SETUP_ARGS}"
  if [ -e "${ksysroot_dir}/cross.txt" ]; then
    MESON_SETUP_ARGS="--cross-file=${ksysroot_dir}/cross.txt ${MESON_SETUP_ARGS}"
  fi

  local build_dir
  for i in c cxx; do
    build_dir="build-${base}-$i"
    rm -rf "${build_dir}"

    echo MESON_SETUP_ARGS="${MESON_SETUP_ARGS}"
    echo MESON_COMPILE_ARGS="${MESON_COMPILE_ARGS}"

    # shellcheck disable=SC2086
    ${MESON} setup ${MESON_SETUP_ARGS} "${build_dir}" "${KSYSROOT_PREFIX}/test-$i" && ${MESON} compile ${MESON_COMPILE_ARGS} -C "${build_dir}"
    test -x "${build_dir}"/main
    file "${build_dir}"/main
  done
}

ksysroot_test_pkgconf() {
  local ksysroot_dir="$1"
  local PKG_CONFIG1 PKG_CONFIG2
  local env

  env="$(echo "${ksysroot_dir}"/bin/*-env)"

  echo envfile is "${env}"
  # shellcheck disable=SC2016
  PKG_CONFIG1="$("${env}" sh -c 'echo ${PKG_CONFIG}')"
  test -z "${CC}" || echo Should not have leaked \$CC
  echo PKG_CONFIG="${PKG_CONFIG1}"

  # shellcheck disable=SC1090
  PKG_CONFIG2="$(set -- && . "${env}" && echo "${PKG_CONFIG}")"
  test -z "${CC}" || echo Should not have leaked \$CC
  echo PKG_CONFIG="${PKG_CONFIG2}"

  test "${PKG_CONFIG1}" = "${PKG_CONFIG2}" || echo Should be the same "${PKG_CONFIG1}" = "${PKG_CONFIG2}"

  "${PKG_CONFIG1}" --list-all
}

ksysroot_test() {
  ksysroot_test_wrapper "$@"
  ksysroot_test_pkgconf "$@"
  ksysroot_test_meson "$@"
}

test_all() {
  test_sysroot native

  # add from Alpine or OpenWRT
  # x86_64-linux-musl
  # arm-linux-musleabi
  # arm-linux-musleabihf
}

usage() {
  echo "Usage: $0 <command> [<args>]"
  echo
  echo "Iteration"
  echo "    iterate                                   Iterate all known triples"
  echo "    iterate{1|2|3}                            Iterate tier-{1|2|3} triples"
  echo
  echo "Installation"
  echo "    bom <triple>                              Emit BOM for triple"
  echo "    frombom <target-directory> [bomfile]      Install from BOM/stdin into target-directory"
  echo "    install <triple> <target-directory>       Install directly into target-directory"
  echo
  echo "Test"
  echo "    test <directory>                          Run all tests in <directory>"
  echo "    test_{wrapper|meson|pkgconf} <directory>  Run specific test in <directory>"
}

dispatch() {
  local cmd="$1"
  shift
  case "${cmd}" in
    test | test_wrapper | test_meson | test_pkgconf)
      ksysroot_"${cmd}" "$1"
      ;;
    frombom)
      ksysroot_frombom "$@"
      ;;
    iterate*)
      ksysroot_native_"${cmd}"
      ksysroot_debian_"${cmd}"
      ksysroot_freebsd_"${cmd}"
      ;;
    *)
      case "$1" in
        *linux*-gnu | *@debian*)
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
          ;;
      esac
      1>&2 echo Performed "${cmd}" "$@" for "${KSYSROOT_TRIPLE}" in "${KSYSROOT_PREFIX}"
      ;;
  esac
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

dispatch "$@"
