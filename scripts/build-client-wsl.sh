#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
client_dir="$repo_root/client"
build_dir="${1:-$client_dir/Build-wsl}"
jobs="${JOBS:-$(nproc)}"

if [[ ! -f "$client_dir/CMakeLists.txt" ]]; then
    echo "Could not find client/CMakeLists.txt under $repo_root" >&2
    exit 1
fi

cmake -S "$client_dir" -B "$build_dir"
cmake --build "$build_dir" --parallel "$jobs"

if command -v ldd >/dev/null 2>&1; then
    missing_libs="$(ldd "$client_dir/Havoc" | grep 'not found' || true)"
    if [[ -n "$missing_libs" ]]; then
        echo "$missing_libs" >&2
        echo "The client built, but WSL is missing runtime libraries listed above." >&2
        exit 1
    fi
fi

echo "Built $client_dir/Havoc"