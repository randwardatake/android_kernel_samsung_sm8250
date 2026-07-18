#!/usr/bin/env bash
set -e
cd /home/randward/android_kernel_samsung_sm8250

build_profile() {
    local PROFILE="$1" FREQ="$2" VLVL="$3"
    echo "########## BUILDING PROFILE: $PROFILE (freq=$FREQ vlvl=$VLVL) ##########"
    PROFILE="$PROFILE" OC_FREQ="$FREQ" OC_VLVL="$VLVL" bash build.sh 2>&1 | tail -8
    echo "########## DONE: $PROFILE ##########"
}

# Only safe + max tested profiles (per user: no risky MAX-voltage builds)
build_profile safe-800 800000000 416
build_profile oc-940   940800000 450

echo "=== ALL PROFILES BUILT ==="
ls -la antigravity-*.zip 2>&1
