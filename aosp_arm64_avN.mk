#
# aosp_arm64_avN — phh Treble GSI, A-only / vanilla / no GApps / no su
# 目标设备：iFLYTEK CB-C6-STU (ud710_2h10, 非 A/B, 独立 recovery 分区)
#
# 与 bvN 的唯一区别：A-only（a）而非 A/B（b）—— C6 是传统分区布局，
# 没有 _a/_b 槽位，设置 ro.build.ab_update=false，避免系统走 A/B 更新/挂载路径。
#
# vndklite：bionic 侧保留 vndklite 代码 + ro.vndk.lite=true +
# 自定义 ld.config.vndk_lite.txt（default namespace 含 vendor vndk-28）
#

$(call inherit-product, device/phh/treble/base-pre.mk)
include build/make/target/product/aosp_arm64.mk
$(call inherit-product, device/phh/treble/base.mk)

# DerpFest 13 has vendor/derp (NOT vendor/aosp)
$(call inherit-product, vendor/derp/config/common_full_phone.mk)

TARGET_BOOT_ANIMATION_RES := 1080

PRODUCT_NAME := aosp_arm64_avN
PRODUCT_DEVICE := arm64_avN
PRODUCT_BRAND := google
PRODUCT_SYSTEM_BRAND := google
PRODUCT_MODEL := Phh-Treble GSI vndklite (A-only)
PRODUCT_CHARACTERISTICS := device

# ---- A-only（非 A/B）----
PRODUCT_SYSTEM_PROPERTIES += \
    ro.build.ab_update=false

# ---- vndklite ----
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
