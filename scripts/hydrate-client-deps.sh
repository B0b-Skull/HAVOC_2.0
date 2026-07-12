#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

clone_or_update() {
    local path="$1"
    local url="$2"

    if [[ -d "$path/.git" ]]; then
        git -C "$path" fetch --depth=1 origin
        git -C "$path" reset --hard FETCH_HEAD
        return
    fi

    if [[ -d "$path" ]] && [[ -n "$(find "$path" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
        echo "[*] $path already has files; leaving it in place"
        return
    fi

    rm -rf "$path"
    git clone --depth=1 "$url" "$path"
}

if [[ -d .git ]]; then
    git submodule update --init --recursive || true
fi

clone_or_update client/external/spdlog https://github.com/gabime/spdlog.git
clone_or_update client/external/json https://github.com/nlohmann/json.git
clone_or_update client/external/toml https://github.com/ToruNiina/toml11.git