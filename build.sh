#!/usr/bin/env bash
set -e
set -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ROOT_DIR="$(pwd)"
source dependencies.lock
bash tools/setup-dependencies.sh

SECONDS=0 # builtin bash timer

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

export DEVICE

# ===== AnyKernel3 =====

ZIPNAME="aospksu-$(date '+%Y%m%d').zip"
TC_DIR="$(pwd)/tc/clang"
DEFCONFIG="vendor/kona-perf_defconfig vendor/samsung/kona-sec-common.config vendor/samsung/$DEVICE.config vendor/extra/ksu.config vendor/extra/droidspaces.config"

OUT_DIR="$(pwd)/out"
BOOT_DIR="$OUT_DIR/arch/arm64/boot"
DTS_DIR="$BOOT_DIR/dts/vendor/qcom"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
    ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8)-$DEVICE.zip"
fi



export PATH="$TC_DIR/bin:$PATH"

mkdir -p out
echo -e "${YELLOW}building with: $DEFCONFIG${NC}"

make O=out ARCH=arm64 $DEFCONFIG
make O=out ARCH=arm64 olddefconfig

echo -e "\n${YELLOW}Starting compilation...${NC}\n"

make -j$(nproc --all) O=out ARCH=arm64 \
    CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 LLVM_IAS=1 dtbo.img
    
make -j$(nproc --all) O=out ARCH=arm64 \
    CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 LLVM_IAS=1 Image
    
if [ -s "$BOOT_DIR/Image" ] && [ -s "$BOOT_DIR/dtbo.img" ]; then
    echo -e "${GREEN}Kernel Image found!${NC}"
    
    if [ -d "$DTS_DIR" ]; then
        echo -e "${BLUE}Generating dtb from $DTS_DIR...${NC}"
        mapfile -d '' -t DTB_FILES < <(find "$DTS_DIR" -type f -name "*.dtb" -print0 | sort -z)
        test "${#DTB_FILES[@]}" -gt 0
        cat "${DTB_FILES[@]}" > "$BOOT_DIR/dtb"
        
        if [ -s "$BOOT_DIR/dtb" ]; then
            echo -e "${GREEN}dtb generated successfully!${NC}"
        else
            echo -e "${RED}Failed to generate dtb! Check if dtbs were compiled.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}DTS directory not found. Compilation might be incomplete.${NC}"
        exit 1
    fi
else
    echo -e "\n${RED}Compilation failed! Image not found.${NC}"
    exit 1
fi

echo "Preparing clean AnyKernel3 package..."

PACKAGE_DIR="$(mktemp -d)"
trap 'rm -rf -- "$PACKAGE_DIR"' EXIT

git -C AnyKernel3 archive "$AK3_COMMIT" | tar -xf - -C "$PACKAGE_DIR"

cp "$BOOT_DIR/Image" "$PACKAGE_DIR/Image"
cp "$BOOT_DIR/dtb" "$PACKAGE_DIR/dtb"
cp "$BOOT_DIR/dtbo.img" "$PACKAGE_DIR/dtbo.img"

test -s "$PACKAGE_DIR/Image"
test -s "$PACKAGE_DIR/dtb"
test -s "$PACKAGE_DIR/dtbo.img"

(
    cd "$PACKAGE_DIR"
    zip -r9 "$PACKAGE_DIR/$ZIPNAME" * \
        -x README.md '*placeholder'
)

unzip -tq "$PACKAGE_DIR/$ZIPNAME"
mv "$PACKAGE_DIR/$ZIPNAME" "$ROOT_DIR/$ZIPNAME"

echo -e "\n${GREEN}Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!${NC}"
echo -e "${GREEN}Zip: $ZIPNAME${NC}"
