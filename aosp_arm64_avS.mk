#
# aosp_arm64_avS — phh Treble GSI, A-only / vanilla / no GApps / WITH su (root)
# 目标设备：iFLYTEK CB-C6-STU (ud710_2h10, 非 A/B, 独立 recovery 分区)
#
# 变体含义：
#   a = A-only（非 A/B）
#   v = vanilla（无 GApps）
#   S = 带 su（root 支持，通过 phh-su prebuilt + sudaemon）
# 附加：vndklite（bionic 侧 vndklite + ro.vndk.lite=true + 自定义 ld.config）
#

$(call inherit-product, device/phh/treble/base-pre.mk)
include build/make/target/product/aosp_arm64.mk
$(call inherit-product, device/phh/treble/base.mk)

# DerpFest 13 has vendor/derp (NOT vendor/aosp)
$(call inherit-product, vendor/derp/config/common_full_phone.mk)

# ---- 最小 GMS：只要 Play 服务 + Play 商店 + GSF（约 200MB）----
# v18 起停用：本机无 SIM、无账号需求，保持纯 vanilla。需要时取消下面注释即可恢复。
# 不使用 WITH_GMS=true，那条路径会带入 Velvet/Chrome/Photos 等整套 Pixel 应用（1.5GB+），
# system 分区装不下。这里只继承自建的极简清单。
$(call inherit-product, vendor/gms/minimal-gms.mk)

TARGET_BOOT_ANIMATION_RES := 1080

PRODUCT_NAME := aosp_arm64_avS
PRODUCT_DEVICE := arm64_avS
PRODUCT_BRAND := google
PRODUCT_SYSTEM_BRAND := google
PRODUCT_MODEL := C6-STU
PRODUCT_CHARACTERISTICS := device

# ---- A-only（非 A/B）----
PRODUCT_SYSTEM_PROPERTIES += \
    ro.build.ab_update=false

# ---- vndklite ----
PRODUCT_SYSTEM_PROPERTIES += \
    ro.vndk.lite=true

PRODUCT_COPY_FILES += \
    device/phh/treble/ld.config.vndk_lite.txt:system/etc/ld.config.vndk_lite.txt

# ---- 显示亮度 ramp 配置（CB-C6）----
# 展锐 vendor lights HAL 并发写背光会乱序，把 ramp 提到 1000 让每次调节落为单帧写入，
# 避免拖动亮度条时闪烁（真凶 vendor HAL 已由 lightsfix 替换，此处固化 ramp 配置）。
PRODUCT_COPY_FILES += \
    device/phh/treble/displayconfig/display_0.xml:system/product/etc/displayconfig/display_0.xml \
    device/phh/treble/displayconfig/display_port_0.xml:system/product/etc/displayconfig/display_port_0.xml

# ---- su (root) ----
# phh-su: prebuilt ARM 静态二进制 (/system/bin/phh-su) + sudaemon 服务
# sepolicy 由 device/phh/treble/sepolicy（su.te / file_contexts）提供，
# 已在 base.mk 里通过 SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS 挂载
PRODUCT_PACKAGES += \
    phh-su

# CB-C6: 关闭 SystemUI 的背景模糊（控制中心 / 通知栏下拉）。
# 该平台 blur 管线输出线性空间数据且未转回 sRGB，导致画面发灰，
# 详见 system_blurfix 说明。Launcher 那半由 Settings.Global.disable_window_blurs
# 的默认值控制（见 SettingsProvider defaults.xml 的 def_disable_window_blurs）。
PRODUCT_SYSTEM_PROPERTIES += \
    persist.sysui.disableBlur=1

# ---- 默认时区：GMT+08:00 中国标准时间 ----
# SystemServer 首启读 persist.sys.timezone 定时区；本机无 SIM/NITZ，不设会落 GMT。
# 注意：若 /data 里已持久化过其他时区，该值不覆盖，需手动 setprop 或清数据。
PRODUCT_SYSTEM_PROPERTIES += \
    persist.sys.timezone=Asia/Shanghai

# ---- 设备标识（CB-C6-STU）----
# ro.product.model / ro.product.name 由 init 在 property_initialize_ro_product_props()
# 里从 ro.product.<partition>.* 派生；这里直接显式写死，让派生逻辑跳过。
# PRODUCT_MODEL 会生成 ro.product.system.model，两者最终都指向 C6-STU。
# maintainer 在 AOSP 里没有既定 key，属于 DerpFest/Lineage 风格的展示字段。
PRODUCT_SYSTEM_PROPERTIES += \
    ro.product.model=C6-STU \
    ro.product.name=C6-STU \
    ro.build.maintainer=Blackemmm \
    ro.product.maintainer=Blackemmm

# ---- SurfaceFlinger 色彩模式（原 colorfix 模块）----
# 默认 kEnhanced(2) 会走 RenderIntent::ENHANCE（过饱和）。
# native_mode=0 -> kManaged -> COLORIMETRIC，配合 saturation=1.0 得到中性准确的色彩。
# 注意：早先 colorfix 用 resetprop 在 post-fs-data 阶段写，被 SELinux 静默拦截从未生效，
# 这里改为编译期写入属性，绕开该问题。
PRODUCT_SYSTEM_PROPERTIES += \
    persist.sys.sf.native_mode=0 \
    persist.sys.sf.color_saturation=1.0

# ---- 蓝牙 GD 栈：跳过 APCF 扩展特性读取（原 btfix 模块）----
# 该平台配合 APCF 扩展特性时，0xFD57 的响应会与 0x2041 的命令完成事件交叉，
# 触发 hci_layer.cc:183 的 ASSERT_LOG 崩溃。禁用后不再发该命令。
PRODUCT_SYSTEM_PROPERTIES += \
    bluetooth.le.disable_apcf_extended_features=1

# ---- 预装第三方应用（vendor/c6prebuilts/Android.mk）----
# Iconify：QS/状态栏/通知面板深度定制，需 root（本机有 Magisk），FOSS 版无专有依赖
# Via：轻量浏览器（官方 mark.via）
# 定义在 vendor/c6prebuilts/Android.mk：BUILD_PREBUILT + PRESIGNED + SDK_VERSION=33
# → 命中 do_not_alter_apk 分支，原样拷贝，签名不被破坏（细节见该文件注释）。
PRODUCT_PACKAGES += \
    Iconify \
    Iconify_libaapt \
    Iconify_libaapt2 \
    Iconify_libzipalign \
    Iconify_libandroidx_graphics_path \
    Via

IS_PHONE := true
TARGET_SUPPORTS_QUICK_TAP := true
TARGET_SUPPORTS_GOOGLE_RECORDER := false
TARGET_INCLUDE_STOCK_ACORE := false
TARGET_INCLUDE_LIVE_WALLPAPERS := false
TARGET_FACE_UNLOCK_SUPPORTED := true
