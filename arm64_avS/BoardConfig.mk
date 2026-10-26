include build/make/target/board/generic_arm64/BoardConfig.mk
include device/phh/treble/board-base.mk

ifeq ($(BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE),)
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
else
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 33554432
endif

# A-only 设备（非 A/B）：C6 为传统分区布局，有独立 recovery 分区
AB_OTA_UPDATER := false

# CB-C6: 预装 Iconify 的 aapt/aapt2/zipalign 本质是可执行文件，需要 0755。
# fs_config 对 /system/app/** 默认 0644，会把安装时的 0755 覆盖掉，故单独声明。
TARGET_FS_CONFIG_GEN += device/phh/treble/fs_config_c6.cfg
