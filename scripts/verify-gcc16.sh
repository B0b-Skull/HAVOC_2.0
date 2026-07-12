#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "[*] Toolchain"
go version
x86_64-w64-mingw32-gcc --version | head -n 1
i686-w64-mingw32-gcc --version | head -n 1
nasm --version
cmake --version | head -n 1

echo "[*] Hydrating client dependencies"
bash scripts/hydrate-client-deps.sh

echo "[*] Building shellcode templates"
make -C payloads/Shellcode clean all

echo "[*] Building DLL loader template"
make -C payloads/DllLdr clean all

echo "[*] Compile-checking Demon x64 with modern MinGW"
bash scripts/verify-demon-compile.sh x64

echo "[*] Compile-checking Demon x86 with modern MinGW"
bash scripts/verify-demon-compile.sh x86

echo "[*] Building teamserver"
make dev-ts-compile

echo "[*] Configuring client"
cmake -S client -B client/Build -DCMAKE_BUILD_TYPE=Release

echo "[*] Building client"
cmake --build client/Build --parallel 2