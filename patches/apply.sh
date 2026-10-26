#!/usr/bin/env bash
# ============================================================================
# CB-C6-STU 系统层补丁应用脚本
#
# 用法：
#   bash patches/apply.sh /path/to/aosp          # 用完整文件覆盖（推荐，最稳）
#   bash patches/apply.sh /path/to/aosp --patch  # 用 diff 打补丁（仅 SystemUI 三处）
#   bash patches/apply.sh /path/to/aosp --check  # 只检查不修改
#
# 说明：这些修复不在设备树里，它们改的是 frameworks/base、Settings、MediaProvider
#       的源码。设备树只提供产品配置，所以必须单独打这批补丁才能得到同样的系统。
# ============================================================================
set -u

TREE="${1:-}"
MODE="${2:-copy}"

if [ -z "$TREE" ] || [ ! -d "$TREE" ]; then
    echo "用法: bash patches/apply.sh /path/to/aosp [--patch|--check]"
    exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HERE/backup-$STAMP"
changed=0
failed=0

echo "== 目标源码树: $TREE"
echo "== 模式: $MODE"
echo

# ---------- 1. 完整文件覆盖 ----------
apply_copy() {
    echo "---- 覆盖改动文件 ----"
    while IFS= read -r rel; do
        src="$HERE/files/$rel"
        dst="$TREE/$rel"
        relpath="${rel#./}"
        if [ ! -f "$dst" ]; then
            echo "  [跳过] 目标不存在: $relpath"
            failed=$((failed + 1))
            continue
        fi
        if cmp -s "$src" "$dst"; then
            echo "  [一致] $relpath"
            continue
        fi
        if [ "$MODE" = "--check" ]; then
            echo "  [待改] $relpath"
            changed=$((changed + 1))
            continue
        fi
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp "$dst" "$BACKUP/$rel"
        cp "$src" "$dst"
        echo "  [已改] $relpath"
        changed=$((changed + 1))
    done < <(cd "$HERE/files" && find . -type f | sed 's|^\./||')
}

# ---------- 2. diff 补丁 ----------
apply_patch() {
    echo "---- 打 diff 补丁 ----"
    for p in "$HERE"/frameworks_base/*.patch; do
        [ -f "$p" ] || continue
        if [ "$MODE" = "--check" ]; then
            if (cd "$TREE" && git apply --check "$p" 2>/dev/null); then
                echo "  [可打] $(basename "$p")"
                changed=$((changed + 1))
            else
                echo "  [不可打] $(basename "$p")（上游已改或已打过）"
                failed=$((failed + 1))
            fi
        else
            if (cd "$TREE" && git apply "$p" 2>/dev/null); then
                echo "  [已打] $(basename "$p")"
                changed=$((changed + 1))
            else
                echo "  [失败] $(basename "$p") —— 退回用 --copy 模式"
                failed=$((failed + 1))
            fi
        fi
    done
}

# ---------- 3. vendor 配置（新增文件，直接放入）----------
apply_vendor() {
    echo "---- 放入 vendor 配置 ----"
    while IFS= read -r rel; do
        src="$HERE/vendor/$rel"
        dst="$TREE/vendor/$rel"
        if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
            echo "  [一致] vendor/$rel"
            continue
        fi
        if [ "$MODE" = "--check" ]; then
            echo "  [待放] vendor/$rel"
            changed=$((changed + 1))
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  [已放] vendor/$rel"
        changed=$((changed + 1))
    done < <(cd "$HERE/vendor" && find . -type f | sed 's|^\./||' | sed 's|^\./||')
}

if [ "$MODE" = "--patch" ]; then
    apply_patch
else
    apply_copy
    apply_vendor
fi

echo
echo "== 完成：$changed 项处理，$failed 项跳过/失败"
if [ -d "$BACKUP" ]; then
    echo "== 原文件已备份到: $BACKUP"
fi
echo
cat <<'NOTE'
提示：
1. 覆盖文件后必须重新编译对应模块，只换文件不重编会因 odex 与源码不一致而不生效。
   推荐直接重新出 system.img（本设备为 GSI，改 system 后必须整包刷）。
2. vendor/gms/minimal-gms.mk 与 vendor/c6prebuilts/Android.mk 放好后，
   需要在 device/phh/treble/aosp_arm64_avS.mk 里引用（本设备树已包含这部分）。
3. c6prebuilts 还需要 APK 本体（Iconify.apk / Via.apk）和 Iconify 的 4 个 arm64 库，
   这些是第三方二进制，不随本仓库分发，请自行下载后放到对应目录。
NOTE
