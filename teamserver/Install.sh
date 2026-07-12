#!/bin/bash
set -euo pipefail

missing=()
for tool in go nasm x86_64-w64-mingw32-gcc i686-w64-mingw32-gcc; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing+=( "$tool" )
    fi
done

if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing build tools: ${missing[*]}"

    if [ "$(id -u)" -eq 0 ] && command -v pacman >/dev/null 2>&1; then
        pacman -Syu --noconfirm --needed go nasm mingw-w64-gcc
    elif [ "$(id -u)" -eq 0 ] && command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go nasm mingw-w64
    else
        echo "Install Go, nasm, and MinGW-w64 GCC 15+ or use docker compose up havoc-dev."
        exit 1
    fi
fi

mkdir -p data