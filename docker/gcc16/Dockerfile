FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
        base-devel \
        cmake \
        git \
        go \
        libcap \
        mingw-w64-gcc \
        nasm \
        nlohmann-json \
        python \
        python-pefile \
        qt6-base \
        qt6-tools \
        qt6-websockets \
        spdlog \
        sudo \
        wget \
    && pacman -Scc --noconfirm

ENV GO111MODULE=on