#!/bin/bash
set -euo pipefail

missing=()

tools=(
    go
    nasm
    x86_64-w64-mingw32-gcc
    i686-w64-mingw32-gcc
    cmake
    make
)

for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing+=( "$tool" )
    fi
done

# Check Qt development packages separately
if ! dpkg -s libqt5websockets5-dev >/dev/null 2>&1; then
    missing+=( "libqt5websockets5-dev" )
fi

if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing dependencies:"
    printf ' - %s\n' "${missing[@]}"

    if [ "$(id -u)" -eq 0 ] && command -v apt-get >/dev/null 2>&1; then
        apt-get update

        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            golang-go \
            nasm \
            mingw-w64 \
            cmake \
            build-essential \
            qtbase5-dev \
            libqt5websockets5-dev \
            libqt5svg5-dev

    elif [ "$(id -u)" -eq 0 ] && command -v pacman >/dev/null 2>&1; then
        pacman -Syu --noconfirm --needed \
            go \
            nasm \
            mingw-w64-gcc \
            cmake \
            qt5-base \
            qt5-websockets

    else
        echo "Please run as root or install dependencies manually."
        exit 1
    fi
fi

# Verify compiler and build tool versions
echo "[*] Checking build tool versions"

echo "Go:"
go version

echo "GCC:"
gcc --version | head -n 1

echo "CMake:"
cmake --version | head -n 1

echo "MinGW x86_64:"
x86_64-w64-mingw32-gcc --version | head -n 1

echo "MinGW i686:"
i686-w64-mingw32-gcc --version | head -n 1

mkdir -p data
