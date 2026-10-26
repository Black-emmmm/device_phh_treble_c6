#
# CB-C6 最小 GMS 配置（只有基础功能 + Play 商店）
#
# 只装 5 个包，不含 Velvet/Chrome/Photos/Gmail 等大件：
#   PrebuiltGmsCoreSc        Google Play 服务本体      (~121MB)
#   AndroidPlatformServices  Play 服务的独立组件      (~14MB)
#   Phonesky                 Google Play 商店          (~58MB)
#   GoogleServicesFramework  账号/同步框架（GSF）      (~7.3MB)
#   GoogleExtShared          GMS 共享库                (~17KB)
# 合计约 200MB。
#
# 附带必需的权限白名单与 sysconfig，否则 priv-app 启动时会被
# ro.control_privapp_permissions 拦下（userdebug 也是 enforce）。
#
# 注意：本机 system 分区只有 2.87GB，已几乎写满，所以必须同时在
# 编译时裁掉用不到的 VNDK apex（见 build_systemimage.sh 里的
# OVERRIDE_PRODUCT_EXTRA_VNDK_VERSIONS），否则镜像会塞不下。
#

PRODUCT_SOONG_NAMESPACES += \
    vendor/gms/common

PRODUCT_PACKAGES += \
    GoogleExtShared \
    PrebuiltGmsCoreSc \
    AndroidPlatformServices \
    Phonesky \
    GoogleServicesFramework

# ---- 权限白名单 / 默认权限 / 系统配置 ----
PRODUCT_COPY_FILES += \
    vendor/gms/common/proprietary/system/etc/permissions/privapp-permissions-google.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-google.xml \
    vendor/gms/common/proprietary/system_ext/etc/permissions/privapp-permissions-google-se.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-google-se.xml \
    vendor/gms/common/proprietary/product/etc/permissions/privapp-permissions-google-p.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-google-p.xml \
    vendor/gms/common/proprietary/product/etc/permissions/split-permissions-google.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/split-permissions-google.xml \
    vendor/gms/common/proprietary/product/etc/default-permissions/default-permissions.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/default-permissions/default-permissions.xml \
    vendor/gms/common/proprietary/product/etc/sysconfig/google.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/sysconfig/google.xml \
    vendor/gms/common/proprietary/product/etc/sysconfig/google_build.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/sysconfig/google_build.xml \
    vendor/gms/common/proprietary/product/etc/sysconfig/google-hiddenapi-package-whitelist.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/sysconfig/google-hiddenapi-package-whitelist.xml \
    vendor/gms/common/proprietary/product/etc/preferred-apps/google.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/preferred-apps/google.xml

# Play 商店/账号识别用，缺了会提示「此设备未获得 Play 保护认证」
PRODUCT_PRODUCT_PROPERTIES += \
    ro.com.google.clientidbase=android-google
