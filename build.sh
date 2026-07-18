#!/usr/bin/env bash
set -e

# Append Proton Clang to the END of PATH
export PATH="$PATH:/home/randward/proton-clang/bin"

# Architecture and Compilation Variables
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

OUT_DIR="out"
mkdir -p $OUT_DIR

echo "=== Merging Kernel Configurations (Pure Overclock & Audio) ==="
scripts/kconfig/merge_config.sh -m -O $OUT_DIR \
    arch/arm64/configs/vendor/kona-perf_defconfig \
    arch/arm64/configs/vendor/samsung/kona-sec-common.config \
    arch/arm64/configs/vendor/samsung/gts7l.config \
    arch/arm64/configs/vendor/samsung/gts7lwifi.config

echo "=== Disabling KSU & Droidspaces, Adding Audio & BBR Optimization ==="
cat <<EOC >> $OUT_DIR/.config
# --- Disable KernelSU & Kprobes ---
# CONFIG_KSU is not set
# CONFIG_KSU_MANUAL_HOOK is not set
# CONFIG_KPROBES is not set

# --- High Fidelity & Precision Audio (SND_HRTIMER) ---
CONFIG_SND_HRTIMER=y
CONFIG_SND_SEQ_HRTIMER_DEFAULT=y
CONFIG_SND_USB_AUDIO_USE_PIPEAHEAD=y
CONFIG_TCP_CONG_BBR=y
CONFIG_DEFAULT_TCP_CONG="bbr"

# --- Memory & ZRAM Optimization ---
CONFIG_ZRAM_DEF_COMP_ZSTD=y
EOC

echo "=== Updating defconfig (olddefconfig) ==="
make O=$OUT_DIR \
    HOSTCC=gcc \
    HOSTLD=ld \
    CC=clang \
    LLVM=1 \
    LLVM_IAS=1 \
    olddefconfig

echo "=== Starting Kernel Compilation (Pure Overclock) ==="
make O=$OUT_DIR \
    HOSTCC=gcc \
    HOSTLD=ld \
    CC=clang \
    LLVM=1 \
    LLVM_IAS=1 \
    -j$(nproc)

if [ -f "$OUT_DIR/arch/arm64/boot/Image" ]; then
    echo "=== COMPILATION SUCCESSFUL! ==="
    echo "Output File: $OUT_DIR/arch/arm64/boot/Image"
else
    echo "=== COMPILATION FAILED! ==="
    exit 1
fi
