#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

source dependencies.lock

prepare_repo() {
    local dir="$1"
    local repo="$2"
    local commit="$3"

    if [ ! -e "$dir" ]; then
        git clone "$repo" "$dir"
    fi

    if [ "$(git -C "$dir" remote get-url origin)" != "$repo" ]; then
        echo "ERROR: Unexpected remote in $dir"
        exit 1
    fi

    if [ -n "$(git -C "$dir" status --porcelain --untracked-files=no)" ]; then
        echo "ERROR: Local modifications in $dir"
        exit 1
    fi

    if ! git -C "$dir" cat-file -e "${commit}^{commit}" 2>/dev/null; then
        git -C "$dir" fetch origin "$commit"
    fi

    git -C "$dir" checkout --detach "$commit"

    test "$(git -C "$dir" rev-parse HEAD)" = "$commit"

    echo "[OK] $dir: $commit"
}

echo "=== Preparing sKernelSU ==="

prepare_repo KernelSU "$KSU_REPO" "$KSU_COMMIT"

if [ -L drivers/kernelsu ]; then
    test "$(readlink drivers/kernelsu)" = "../KernelSU/kernel"
elif [ -e drivers/kernelsu ]; then
    echo "ERROR: drivers/kernelsu already exists"
    exit 1
else
    ln -s ../KernelSU/kernel drivers/kernelsu
fi

test -f drivers/kernelsu/Kconfig

grep -Fq 'obj-$(CONFIG_KSU) += kernelsu/' drivers/Makefile
grep -Fq 'source "drivers/kernelsu/Kconfig"' drivers/Kconfig

echo "=== Preparing AnyKernel3 ==="

prepare_repo AnyKernel3 "$AK3_REPO" "$AK3_COMMIT"

echo "=== Preparing Neutron Clang ==="

if [ ! -d tc/clang ]; then
    ARCHIVE="${TOOLCHAIN_PATH:-$ROOT/../backups/$TOOLCHAIN_ARCHIVE}"

    mkdir -p tc

    if [ -f "$ARCHIVE" ]; then
        echo "Using preserved toolchain archive"
        printf '%s  %s\n' "$TOOLCHAIN_SHA256" "$ARCHIVE" | sha256sum -c -
        tar --zstd -xf "$ARCHIVE" -C tc
    elif [ -n "${TOOLCHAIN_PATH:-}" ]; then
        echo "ERROR: Specified toolchain archive not found"
        exit 1
    else
        echo "Downloading pinned Neutron Clang release"
        TMP_DIR="$(mktemp -d)"
        trap 'rm -rf -- "$TMP_DIR"' EXIT

        curl -fL --retry 3 "$TOOLCHAIN_URL" -o "$TMP_DIR/toolchain.tar.zst"

        printf '%s  %s\n' "$TOOLCHAIN_DOWNLOAD_SHA256" "$TMP_DIR/toolchain.tar.zst" | sha256sum -c -

        mkdir -p "$TMP_DIR/clang"
        tar --zstd -xf "$TMP_DIR/toolchain.tar.zst" -C "$TMP_DIR/clang"

        mv "$TMP_DIR/clang" tc/clang
        rm -rf -- "$TMP_DIR"
        trap - EXIT
    fi
fi
printf '%s  %s\n' "$CLANG_SHA256" "tc/clang/bin/clang" | sha256sum -c -
printf '%s  %s\n' "$LLD_SHA256" "tc/clang/bin/ld.lld" | sha256sum -c -

echo "=== All dependencies validated ==="
