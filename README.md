# device_phh_treble_c6

iFLYTEK **CB-C6-STU**（`ud710_2h10`，Unisoc UD710）的 Android 13 GSI 设备树。

用于构建 `aosp_arm64_avS`（arm64 A/B-less vndklite GSI）并刷入本机。
成品镜像为 `system_avS_v22_gms.img`（2.62 GiB，含最小 GMS + Iconify + Via）。

| 项 | 值 |
|---|---|
| 基础 | [sounddrill31/device_phh_treble_aosp](https://github.com/sounddrill31/device_phh_treble_aosp) 分支 `thirteen-jemalloc` |
| 分支 | `13.0`（对齐 DerpFest 13） |
| 系统 | Android 13 (T) / DerpFest 13 |
| 设备 | 非 A/B、独立 recovery 分区、无 SIM 卡槽 |
| 屏幕 | LCD 1200×1920 |
| 产品 | `aosp_arm64_avS` |

> 本仓库是以上游设备树为基础、叠加 C6 适配后的完整快照（上游仓库的 git 历史未包含在这一份里）。
> 需要跟随上游时，可直接把上游 `thirteen-jemalloc` 的更新再合进来，C6 的改动都带 `CB-C6` 注释标记，好定位。

---

## 相对上游改了什么

### 产品配置

| 文件 | 改动 |
|---|---|
| `aosp_arm64_avS.mk` | 设备标识（`PRODUCT_MODEL/NAME = C6-STU`）、`persist.sys.timezone=Asia/Shanghai`、最小 GMS 继承、预装 Iconify/Via、亮度 ramp、关闭窗口模糊 |
| `arm64_avS/BoardConfig.mk` | 加 `TARGET_FS_CONFIG_GEN`（见下）、非 A/B 布局 |
| `fs_config_c6.cfg` | **新增**。给 Iconify 的 3 个可执行工具声明 `0755` |
| `base.mk` / `system.prop` / `vndk.rc` / `ld.config.vndk_lite.txt` | VNDK 精简与属性调整 |
| `AndroidProducts.mk` + `aosp_arm64_avN.mk` / `bvN.mk` + 对应 BoardConfig | 产品列表整理 |

### 设备专属目录

| 目录 | 内容 |
|---|---|
| `sepolicy/` | **新增 `iconify.te`**（`iconify_exec` 类型 + 应用域执行授权）；`file_contexts` 加打标 |
| `displayconfig/` | 亮度 ramp 配置（解决亮度调节跳变） |
| `lightsfix/` | 背光 HAL 线性化（`lights.ud710.so` 源码，C 实现） |
| `telephonyoff/` | 关掉 telephony/IMS 特性声明（无 SIM 设备） |
| `su/` | superuser 入口调整 |

### 两个关键坑（写在这里免得后人重踩）

**1. `fs_config` 的段名不能带前导斜杠**

`system.img` 里的文件权限不是安装权限决定的，而是被 `fs_config` 表统一覆盖，
`/system/app/**` 默认 `0644`。要让文件可执行，得自己写 cfg 并在 BoardConfig 挂
`TARGET_FS_CONFIG_GEN`。

但 `libcutils` 的 `fs_config()` 会**先剥掉输入路径的前导 `/`**，而配置里的前缀原样参与
`fnmatch` —— 写成 `[/system/app/...]` 永远匹配不上，静默回落 `0644`，
表现就是「改了完全没生效」。**必须写 `[system/app/...]`**。

**2. SELinux 要给系统分区里的可执行文件单独开类型**

系统应用的库标签是 `system_file`，任何应用域都没有 `execute` 权限。需要新建
`iconify_exec`（`exec_type` + `system_file_type`，结构同 `toolbox_exec`），
在 `file_contexts` 打标，再放开 `untrusted_app` / `shell` 的 execute。

---

## 系统层补丁（不在本仓库里）

设备树之外还有 11 个文件的修改（SystemUI 白雾蒙板、锁屏「没有服务」、设置安全页转圈、
面具本地安装闪退等）。它们改的是 frameworks/base、Settings、MediaProvider，
放在 [`patches/`](patches/) 里，含标准 diff、完整文件和一键脚本：

```bash
bash patches/apply.sh /path/to/aosp
```

详见 [patches/README.md](patches/README.md)。

---

## 构建

```bash
# 1. 拉 DerpFest 13 源码，把本仓库放到 device/phh/treble
repo init -u https://github.com/DerpFest-AOSP/manifests -b 13
repo sync -j8
git clone https://github.com/Black-emmmm/device_phh_treble_c6 -b 13.0 device/phh/treble

# 2. 打系统层补丁
bash device/phh/treble/patches/apply.sh .

# 3. 放入第三方 APK 与 Iconify 的 4 个 arm64 库（见 patches/README.md）

# 4. 编译
source build/envsetup.sh
lunch aosp_arm64_avS-userdebug
m systemimage
```

产物：`out/target/product/arm64_avS/system.img`

> 内存不足时不要并行构建，串行跑；成功判据是日志出现
> `#### build completed successfully` 且 `system.img` 时间戳更新。

## 刷入

```bash
fastboot flash system system.img
fastboot reboot
```

- 同源升级不需要 Format Data。
- 跨大版本（官方系统 → 本 GSI）需 TWRP Format Data + 禁 vbmeta。
- 开机后按一下电源键亮屏（默认熄屏，不是故障）。

## 已知无害噪音

```
F linker: CANNOT LINK EXECUTABLE ".../neuralnetworks@1.2-service-img-nn-hw"
```
官方 vendor 镜像缺 `android.hardware.neuralnetworks@1.2.so`，init 每 5 秒重启它，不影响使用。

## 许可

本仓库为设备适配层，沿用上游 phh treble 的许可。`patches/` 内的改动基于 AOSP（Apache-2.0）。
仓库不含任何第三方 APK，Iconify / Via 请自行从各自官方渠道获取。
