#
# CB-C6 预装第三方应用（固化为系统应用）
#
# ── 踩过的三个坑（务必别改回下面这些写法）──
#
# 1) Soong android_app_import + presigned
#    uncompressEmbeddedJniLibs 会对含压缩 .so 的 APK 做 zip2zip -0 重打包，
#    presigned 只跳过签名不重签 → v2 签名失配。实测 Iconify 33.8MB → 46.8MB，
#    apksigner 报 "DOES NOT VERIFY / Missing META-INF"，开机 PackageManager 拒装。
#
# 2) PRODUCT_COPY_FILES
#    build/make/core/Makefile 里 check-product-copy-files 直接禁止放 .apk，
#    kati 阶段报 "Prebuilt apk found in PRODUCT_COPY_FILES ... use BUILD_PREBUILT instead!"。
#
# 3) BUILD_PREBUILT + MODULE_CLASS := APPS + PRESIGNED + SDK_VERSION>29
#    会命中 app_prebuilt_internal.mk 的 do_not_alter_apk 分支，虽然是纯拷贝，
#    但附带的 check-jni-dex-compression / check-package-alignment 要求 APK 必须是
#    "dex 和 lib 全部 stor 存储 + 4 字节对齐" 的现代格式。GitHub/官网下载的常规 APK
#    的 classes.dex 和 .so 都是 deflate 压缩，直接报
#    "Contains compressed JNI libraries and/or dex files"。
#
# ── 最终方案：LOCAL_MODULE_CLASS := ETC ──
#    ETC 类预编译走 $(transform-prebuilt-to-target)，就是一句 cp，
#    不碰内容、不做 APK 校验，字节级原样落到 system/app/<名>/<名>.apk。
#    好处：APK 的 v1/v2 签名完整保留（已用 apksigner 验证 Verifies），
#          用户日后仍可用官方 APK 直接覆盖升级，不会因签名不一致被拒。
#    代价：不进 apkcerts.txt、不做编译期 dexopt（dex_preopt 本来就该关，
#          GSI 跨设备的 boot classpath 不一定一致，首次开机 ART 自行 verify 即可）。
#
# Iconify：QS/状态栏/通知面板深度定制，需 root（本机有 Magisk）
#          来源 https://github.com/Mahmud0808/Iconify v7.3.0 FOSS
#          包名 com.drdisagree.iconify.foss（FOSS 版无专有依赖，适配无 GMS 环境）
#          注意：v8.0.0 起要求 Android 16，本机 13，只能停 7.3.0 一线
# Via    ：轻量浏览器，来源 https://www.viayoo.com 官方 APK
#          包名 mark.via
#

LOCAL_PATH := $(call my-dir)

# ---- Iconify ----
include $(CLEAR_VARS)
LOCAL_MODULE := Iconify
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_SUFFIX := .apk
LOCAL_SRC_FILES := Iconify/Iconify.apk
LOCAL_MODULE_PATH := $(TARGET_OUT_APPS)/Iconify
include $(BUILD_PREBUILT)

# ---- Via ----
include $(CLEAR_VARS)
LOCAL_MODULE := Via
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_SUFFIX := .apk
LOCAL_SRC_FILES := Via/Via.apk
LOCAL_MODULE_PATH := $(TARGET_OUT_APPS)/Via
include $(BUILD_PREBUILT)

# ============================================================================
# Iconify 原生库副本 —— 少了这一层 Iconify 就废了（v20 首版就栽在这里）
#
# Iconify 的 AndroidManifest 是 android:extractNativeLibs="true"，它在运行时做：
#     new File(applicationInfo.nativeLibraryDir, "libaapt.so")  →  复制到
#     /data/user/0/com.drdisagree.iconify.foss/bin/aapt  然后 chmod 755 执行
# 用 aapt / aapt2 / zipalign 现场编译 RRO overlay。所以这三个 "lib*.so" 其实是
# aarch64 可执行文件（PIE，interpreter /system/bin/linker64），不是 JNI 库。
#
# 系统应用的 nativeLibraryDir 固定为 <codePath>/lib/<abi>，即
#     /system/app/Iconify/lib/arm64
# 只放 APK 不放这个目录，Iconify 复制源不存在，构建 overlay 时报
#     /data/user/0/com.drdisagree.iconify.foss/bin/aapt: inaccessible or not found
#     Title: Failed to build APK for AMAC
#
# 安装名必须和 APK 内条目同名（应用按名字去找），故用 LOCAL_INSTALLED_MODULE_STEM
# 覆盖（模块名 libaapt/libzipalign 已被 host 工具占用，不能直接拿来做模块名）。
# ============================================================================
ICONIFY_LIB_DIR := $(TARGET_OUT_APPS)/Iconify/lib/arm64

include $(CLEAR_VARS)
LOCAL_MODULE := Iconify_libaapt
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_SUFFIX := .so
LOCAL_INSTALLED_MODULE_STEM := libaapt.so
LOCAL_SRC_FILES := Iconify/lib/arm64/libaapt.so
LOCAL_MODULE_PATH := $(ICONIFY_LIB_DIR)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := Iconify_libaapt2
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_SUFFIX := .so
LOCAL_INSTALLED_MODULE_STEM := libaapt2.so
LOCAL_SRC_FILES := Iconify/lib/arm64/libaapt2.so
LOCAL_MODULE_PATH := $(ICONIFY_LIB_DIR)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := Iconify_libzipalign
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_SUFFIX := .so
LOCAL_INSTALLED_MODULE_STEM := libzipalign.so
LOCAL_SRC_FILES := Iconify/lib/arm64/libzipalign.so
LOCAL_MODULE_PATH := $(ICONIFY_LIB_DIR)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := Iconify_libandroidx_graphics_path
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_SUFFIX := .so
LOCAL_INSTALLED_MODULE_STEM := libandroidx.graphics.path.so
LOCAL_SRC_FILES := Iconify/lib/arm64/libandroidx.graphics.path.so
LOCAL_MODULE_PATH := $(ICONIFY_LIB_DIR)
include $(BUILD_PREBUILT)
