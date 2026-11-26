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

    if [ ! -f "$ARCHIVE" ]; then
        echo "ERROR: Toolchain archive not found: $ARCHIVE"
        exit 1
    fi

    printf '%s  %s\n' "$TOOLCHAIN_SHA256" "$ARCHIVE" | sha256sum -c -

    mkdir -p tc
    tar --zstd -xf "$ARCHIVE" -C tc
fi

printf '%s  %s\n' "$CLANG_SHA256" "tc/clang/bin/clang" | sha256sum -c -
printf '%s  %s\n' "$LLD_SHA256" "tc/clang/bin/ld.lld" | sha256sum -c -

echo "=== All dependencies validated ==="
