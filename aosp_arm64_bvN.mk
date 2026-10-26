#
# aosp_arm64_bvN — phh Treble GSI, vanilla / no GApps / no su
# vndklite 变体：bionic + linkerconfig 的 vndklite 代码路径已恢复，
# 且设置 ro.vndk.lite=true，允许 system 使用 vendor 的 VNDK 库。
# 目标设备：iFLYTEK CB-C6-STU (ud710_2h10, Android 9 vendor, VNDK 28)
#

$(call inherit-product, device/phh/treble/base-pre.mk)
include build/make/target/product/aosp_arm64.mk
$(call inherit-product, device/phh/treble/base.mk)

# DerpFest 13 has vendor/derp (NOT vendor/aosp)
$(call inherit-product, vendor/derp/config/common_full_phone.mk)

TARGET_BOOT_ANIMATION_RES := 1080

PRODUCT_NAME := aosp_arm64_bvN
PRODUCT_DEVICE := arm64_bvN
PRODUCT_BRAND := google
PRODUCT_SYSTEM_BRAND := google
PRODUCT_MODEL := Phh-Treble GSI vndklite
PRODUCT_CHARACTERISTICS := device

# ---- vndklite ----
# 1) ro.vndk.lite=true：bionic linker 改读 /system/etc/ld.config.vndk_lite.txt
#    （bionic 侧已恢复 vndklite 代码；linkerconfig 侧保持 IsVndkLiteDevice=false，
#     因为 AOSP 13 的 linkerconfig 已拒绝生成 vndk-lite 配置会直接 exit）
# 2) ld.config.vndk_lite.txt：default namespace 增加 /vendor/${LIB}/vndk-28 搜索路径，
#    让 system 进程能加载 vendor 侧的库（C6 vendor = Android 9 / VNDK 28）
# 3) 保留 /system/lib64/vndk-28 （-> /apex/com.android.vndk.v28/lib64），
#    这是 Android 13 为老 vendor 保留的 VNDK，删掉会导致 C6 的 vendor HAL 无法启动
PRODUCT_SYSTEM_PROPERTIES += \
    ro.vndk.lite=true

PRODUCT_COPY_FILES += \
    device/phh/treble/ld.config.vndk_lite.txt:system/etc/ld.config.vndk_lite.txt

IS_PHONE := true
TARGET_SUPPORTS_QUICK_TAP := true
TARGET_SUPPORTS_GOOGLE_RECORDER := false
TARGET_INCLUDE_STOCK_ACORE := false
TARGET_INCLUDE_LIVE_WALLPAPERS := false
TARGET_FACE_UNLOCK_SUPPORTED := true
