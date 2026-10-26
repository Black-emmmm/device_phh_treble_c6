include build/make/target/board/generic_arm64/BoardConfig.mk
include device/phh/treble/board-base.mk

ifeq ($(BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE),)
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
else
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 33554432
endif

# A-only 设备（非 A/B）：C6 为传统分区布局，有独立 recovery 分区
AB_OTA_UPDATER := false
