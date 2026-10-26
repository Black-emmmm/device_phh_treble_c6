#!/bin/bash
# Replaced by build automation.
# The original script did `git reset --hard FETCH_HEAD` on 20 repos and ran a
# bare `git am` per patch folder, which on DerpFest 13 leaves half the repos in
# a conflicted "am" state and breaks the build.
#
# New behaviour:
#   * auxiliary vendor repos are cloned only when missing
#   * patches are applied once by crdroid-build/apply_patches.py, which degrades
#     gracefully (git am -> git apply -> -C1 -> --reject) and never leaves a
#     conflicted repository behind
#   * a stamp file makes re-sourcing envsetup.sh a no-op

TOP=$(pwd)
DEV=$TOP/device/phh/treble
STAMP=$DEV/.patches-applied
LOG=$TOP/.patch-apply.log

clone_if_missing() {
    dir="$1"; url="$2"; br="$3"
    if [ -d "$TOP/$dir/.git" ] && [ -n "$(ls -A "$TOP/$dir" 2>/dev/null)" ]; then
        return 0
    fi
    echo ">> cloning $dir ($br)"
    rm -rf "$TOP/$dir"
    git clone --depth=1 -q -b "$br" "$url" "$TOP/$dir" || echo "!! WARNING: clone failed for $dir"
}

clone_if_missing vendor/hardware_overlay https://github.com/trebledroid/vendor_hardware_overlay pie
clone_if_missing vendor/vndk-tests      https://github.com/phhusson/vendor_vndk-tests master
clone_if_missing vendor/interfaces      https://github.com/trebledroid/vendor_interfaces android-13.0
clone_if_missing vendor/lptools         https://github.com/phhusson/vendor_lptools master
clone_if_missing packages/apps/QcRilAm  https://github.com/AndyCGYan/android_packages_apps_QcRilAm master

if [ -f "$STAMP" ]; then
    return 0 2>/dev/null || true
fi

echo ">> applying TrebleDroid/UniversalX patches (first run only)"
python3 "$TOP/../../apply_patches.py" TrebleDroid UniversalX 2>&1 | tee "$LOG"
touch "$STAMP"
echo ">> patch application finished, log: $LOG"
