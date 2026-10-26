# CB-C6-STU 系统层补丁

设备树只负责**产品配置**（编哪些包、什么属性、什么策略）。下面这些修复在设备树之外，
改的是 AOSP/DerpFest 的框架和应用源码，必须单独打才能得到与 `system_avS_v22_gms.img` 一致的系统。

## 怎么用

```bash
# 推荐：完整文件覆盖（最稳，不受上游版本影响）
bash patches/apply.sh /path/to/aosp

# 只检查差异，不改任何东西
bash patches/apply.sh /path/to/aosp --check

# 用 diff 打补丁（只有 SystemUI 三处有标准 patch）
bash patches/apply.sh /path/to/aosp --patch
```

覆盖前会把原文件备份到 `patches/backup-<时间戳>/`。**改完必须重编**，只替换源码文件不重编
（或用旧 odex）不会生效。

---

## 一、SystemUI（frameworks/base）

三处都有标准 unified diff，可直接 `git apply`。

### 1. `LightRevealScrim.kt` — 去掉转场白雾蒙板

路径：`packages/SystemUI/src/com/android/systemui/statusbar/LightRevealScrim.kt`

**症状**：锁屏、亮屏唤醒、打开应用的一瞬间，屏幕会出现一层白色雾状蒙板（弧形下缘），
按键截图时必定能抓到。

**根因**：这是 AOSP 钥匙 Guard 的 LightReveal 白色揭示动画。`revealAmount` 语义是
`0 = 完全被遮挡（全白）`、`1 = 完全可见（透明）`，转场时从 0 渐变到 1 就是「白幕揭开」。
本机钥匙 Guard 常驻（AOD + 自动回锁），三个场景全部命中。

**改法**：`revealAmount` 的 setter 恒保持 `1f`，scrim 永不参与合成。

```kotlin
var revealAmount: Float = 1f
    set(value) {
        // CB-C6 (GSI)：恒保持 1f（全透明），禁用白色转场蒙板
        if (field != 1f) {
            field = 1f
            revealEffect.setRevealAmountOnScrim(1f, this)
            ...
        }
    }
```

### 2. `CarrierTextController.java` — 锁屏隐藏「没有服务」

路径：`packages/SystemUI/src/com/android/keyguard/CarrierTextController.java`

**症状**：锁屏顶部一直挂一行灰色的「没有服务」。

**改法**：文案为空，或等于系统默认的 `lockscreen_carrier_default`（即「没有服务」）时把
View 设为 `GONE`；有 SIM 的设备照常显示真实运营商名，不影响功能。

### 3. `QSCarrierGroupController.java` — 控制中心隐藏「没有服务」

路径：`packages/SystemUI/src/com/android/systemui/qs/carrier/QSCarrierGroupController.java`

**症状**：下拉控制中心顶部也有「没有服务」。

**改法**：无 SIM / 飞行模式分支里不再设置并显示 `mNoSimTextView`，只清空各 SIM 槽位的
carrier text 并隐藏。同时移除因此不再使用的 `android.text.TextUtils` import。

> 这两处只影响「无服务」这一种状态。插卡设备不受影响。

---

## 二、Settings（packages/apps/Settings）

### 4. `SystemDashboardFragment.java` — 移除「DerpFest 系统更新」入口

**症状**：设置 → 系统里有个「DerpFest 系统更新」，GSI 没有 OTA 通道，点进去没用。

**根因**：这个入口不是 xml 里的静态项，而是 `buildPreferenceControllers()` 里动态注入的
`UpdatePreferenceController`，只要系统装了 `org.lineageos.updater` 就会显示。

**改法**：从 `buildPreferenceControllers()` 摘掉 `controllers.add(new UpdatePreferenceController(context))`，
并删除对应 import。

### 5. `derp_strings.xml`（英文 + `values-zh-rCN`）— 同步摘要文案

设置首页「系统」栏的摘要写着「语言, 手势, 系统更新, 时间, 备份」，既然入口去掉了，
文案也去掉「系统更新 / updater」。

### 6. `TopLevelSecurityEntryPreferenceController.java` — 修安全页无限转圈

**症状**：设置 → 安全 打开后一直转圈，永远出不来内容。

**根因**：DerpFest 把安全首页硬编码指向 `SecurityHubDashboard`（Google 的 Security Hub），
它依赖 GMS/Phenotype 回调，在没有 GMS 或回调超时时界面就卡在 loading。

**改法**：不再使用 `SecurityHubDashboard.class.getName()`，回落到 AOSP 原生的安全设置页面。

> 注意：不是 `config_enableSafetyCenter` 那个开关的问题，改那个没用。

### 7. `Settings.java` — `getAlternativeFragmentName()` 返回 null

配合第 6 项：避免 Settings 动态解析到替代的 Security Hub fragment，统一走原生安全页。

### 8. `security_dashboard_settings.xml` — 删掉空的 `security_status` 分类

原生安全页里那个空的 `security_status` PreferenceCategory 会渲染出一条空白分隔，
一并去掉。

### 9. `SurveyMixin.java` — 防 Phenotype 代理 NPE

**症状**：设置偶发崩溃 / 日志里 PhenotypeProxy 空指针。

**改法**：`onResume` 里对 `PhenotypeProxy` 的调用包 try/catch，取不到就跳过调研卡片。

---

## 三、MediaProvider（packages/providers/MediaProvider）

### 10. `LocalCallingIdentity.java` — 修面具「从本地安装」闪退

路径：`src/com/android/providers/media/LocalCallingIdentity.java`

**症状**：Magisk 里选「从本地安装」模块时，文件选择器一打开就闪退。

**根因**：无 SIM / 无电话权限场景下 `fromExternal()` 会把 **null 包名**传给
`AppOpsManager.checkPackage()`，触发跨进程 NPE，异常穿过 Binder 把调用方（面具进程）
带崩，Magisk 随后 `System.exit(1)`。

**改法**：`fromExternal(...)` 做 null 安全处理；`getPackageNameInternal()` 不再把 null
传给 `checkPackage`；`getTargetSdkVersionInternal()` 同样加保护。

---

## 四、vendor 配置（新增文件，不是补丁）

| 文件 | 作用 |
|---|---|
| `vendor/gms/minimal-gms.mk` | 最小 GMS 清单：Play 服务（Sc）、Play 商店、AndroidPlatformServices、GSF、GoogleExtShared + 配套权限与 sysconfig，约 199MB。不使用 `WITH_GMS=true`（那会带入整套 Pixel 应用，1.5GB+，system 装不下）。 |
| `vendor/c6prebuilts/Android.mk` | 预装第三方 APK 的模块定义。**必须用 `LOCAL_MODULE_CLASS := ETC`** —— 详见下文。 |

### 预装 APK 为什么只能用 ETC

试过三条路都失败：

1. `android_app_import` + `presigned: true` —— Soong 的 `uncompressEmbeddedJniLibs` 会用
   `zip2zip -0` 把 APK 里压缩的 `.so` 改成不压缩存储重新打包，而 presigned 只跳过签名、
   不重签，**v2 签名直接作废**（实测 33.8MB 被撑到 46.8MB，apksigner 报 `DOES NOT VERIFY`），
   这种包刷进去开机会被 PackageManager 拒装。
2. `PRODUCT_COPY_FILES` —— `build/make/core/Makefile` 明确禁止放 `.apk`，kati 阶段直接报错。
3. `BUILD_PREBUILT + PRESIGNED + LOCAL_SDK_VERSION>29` —— 会走 `do_not_alter_apk` 分支做纯拷贝，
   但附带的对齐/压缩校验要求 dex 和 `.so` 全部「不压缩 + 4 字节对齐」，普通 APK 过不了。

最终方案：`LOCAL_MODULE_CLASS := ETC` + `LOCAL_MODULE_SUFFIX := .apk` +
`LOCAL_MODULE_PATH := $(TARGET_OUT_APPS)/<名>`，纯 `cp`、零校验、字节级原样。
验证结果：镜像内 APK 的 md5 与官方原包完全一致，`apksigner verify` 均 `Verifies`。

### 仓库不含的二进制

以下文件是第三方产物，不随仓库分发，需自行准备：

```
vendor/c6prebuilts/Iconify/Iconify.apk      # Iconify v7.3.0 FOSS
vendor/c6prebuilts/Via/Via.apk              # Via 7.3.3
vendor/c6prebuilts/Iconify/lib/arm64/       # 从 Iconify.apk 里解出的 4 个库
    libaapt.so  libaapt2.so  libzipalign.so  libandroidx.graphics.path.so
```

Iconify 那 4 个「.so」其实是 aarch64 **可执行文件**（PIE，interpreter `/system/bin/linker64`），
它运行时从 `nativeLibraryDir` 复制成自己的 `bin/aapt` 来现场编 RRO overlay。
系统应用的 `nativeLibraryDir` 固定是 `<APK目录>/lib/<abi>`，所以必须手动铺好这一层。
