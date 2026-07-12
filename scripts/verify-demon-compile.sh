#!/usr/bin/env bash
set -euo pipefail

arch="${1:-x64}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/payloads/Demon"
build_dir="/tmp/havoc-demon-${arch}"

rm -rf "$build_dir"
mkdir -p "$build_dir"

common_flags=(
    -std=gnu17
    -fpermissive
    -Os
    -fno-asynchronous-unwind-tables
    -masm=intel
    -fno-ident
    -fpack-struct=8
    -falign-functions=1
    -s
    -ffunction-sections
    -fdata-sections
    -falign-jumps=1
    -w
    -falign-labels=1
    -fPIC
    -Wl,-s,--no-seh,--enable-stdcall-fixup,--gc-sections
    -nostdlib
    -mwindows
    -DTRANSPORT_HTTP
    "-DCONFIG_BYTES={0x00}"
    -DMAIN_THREADED
    -Iinclude
)

pushd "$source_dir" >/dev/null

case "$arch" in
    x64)
        compiler=x86_64-w64-mingw32-gcc
        nasm_format=win64
        entry_symbol=WinMain
        asm_pattern="src/asm/*.x64.asm"
        output="$build_dir/demon.x64.exe"
        ;;
    x86)
        compiler=i686-w64-mingw32-gcc
        nasm_format=win32
        entry_symbol=_WinMain
        asm_pattern="src/asm/*.x86.asm"
        output="$build_dir/demon.x86.exe"
        ;;
    *)
        echo "usage: $0 [x64|x86]" >&2
        exit 2
        ;;
esac

asm_objects=()
for asm_source in $asm_pattern; do
    object="$build_dir/$(basename "${asm_source%.asm}").o"
    nasm -f "$nasm_format" "$asm_source" -o "$object"
    asm_objects+=("$object")
done

"$compiler" \
    src/core/*.c \
    src/crypt/*.c \
    src/inject/*.c \
    "${asm_objects[@]}" \
    src/Demon.c \
    "${common_flags[@]}" \
    -e "$entry_symbol" \
    src/main/MainExe.c \
    -o "$output"

popd >/dev/null