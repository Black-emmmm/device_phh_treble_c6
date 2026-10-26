$(call inherit-product, device/phh/treble/base-pre.mk)
include build/make/target/product/aosp_arm64.mk
$(call inherit-product, device/phh/treble/base.mk)

# Use Scudo instead of Jemalloc
# PRODUCT_USE_SCUDO := true

# DerpFest 13 has vendor/derp (NOT vendor/aosp — that path is Project-Elixir's)
$(call inherit-product, vendor/derp/config/common_full_phone.mk)

TARGET_BOOT_ANIMATION_RES := 1080
TARGET_GAPPS_ARCH := arm64

PRODUCT_NAME := aosp_arm64_bgN
PRODUCT_DEVICE := arm64_bgN
PRODUCT_BRAND := google
PRODUCT_SYSTEM_BRAND := google
PRODUCT_MODEL := Phh-Treble GSI

# Disable "emulator" characteristics
PRODUCT_CHARACTERISTICS := device

# Phone / feature flags (LineageOS-compatible, inherited by DerpFest)
# NOTE: OverlaySettings removed — that package belongs to Project-Elixir and
# does not exist in DerpFest 13 (would cause "module OverlaySettings not found").
IS_PHONE := true
TARGET_SUPPORTS_QUICK_TAP := true
TARGET_SUPPORTS_GOOGLE_RECORDER := false
TARGET_INCLUDE_STOCK_ACORE := false
TARGET_INCLUDE_LIVE_WALLPAPERS := false
TARGET_FACE_UNLOCK_SUPPORTED := true

# GMS
ifeq ($(WITH_GMS),true)
GMS_MAKEFILE=gms_minimal.mk
endif
