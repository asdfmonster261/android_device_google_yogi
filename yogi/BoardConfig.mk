#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Values here are measured from the device or from the B1 factory/OTA images,
# not copied from another device. Anything still unverified is marked TODO
# rather than guessed, because a plausible wrong value is worse than a gap.

TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_BOOTLOADER_BOARD_NAME := yogi
TARGET_SCREEN_DENSITY := 420

# From the running B1 build (ro.build.version.security_patch).
BOOT_SECURITY_PATCH := 2026-09-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

# Architecture: arm64 only, there is no 32-bit userspace on this device
# (ro.product.cpu.abilist is arm64-v8a, ro.zygote is zygote64).
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv9-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a55

# Partition sizes, read off the device with blockdev --getsize64.
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_DTBOIMG_PARTITION_SIZE := 16777216

# A/B with Virtual A/B + compression, and dynamic partitions in super.
AB_OTA_UPDATER := true
BOARD_USES_METADATA_PARTITION := true
# Group name, size and membership come from the B1 OTA payload manifest
# (dynamic_partition_metadata), not from another device.
BOARD_SUPER_PARTITION_GROUPS := google_dynamic_partitions
BOARD_GOOGLE_DYNAMIC_PARTITIONS_SIZE := 10733223936
BOARD_GOOGLE_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_dlkm system_ext product vendor vendor_dlkm
# The group is 4 MiB short of 10 GiB, which is the usual metadata overhead, so
# the physical super partition is exactly 10 GiB.
BOARD_SUPER_PARTITION_SIZE := 10737418240
BOARD_SUPER_PARTITION_METADATA_DEVICE := super

# Virtual A/B is configured product-side with the PRODUCT_VIRTUAL_AB_* variables;
# TARGET_USES_VIRTUAL_AB is not a build variable and was silently doing nothing.
BOARD_USES_RECOVERY_AS_BOOT :=

# Filesystems: the dynamic partitions ship EROFS on this device, userdata is f2fs.
TARGET_USERIMAGES_USE_F2FS := true
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

# Each image we build needs its copy-out target declared.
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm

# Kernel: prebuilt to start with, same approach LineageOS takes for Pixels
# (comet depends on a comet-kernels repo). Our own tree is heybooboo-kernel,
# ACK android16-6.12 based and already booting on this device.
BOARD_KERNEL_IMAGE_NAME := Image.lz4
TARGET_PREBUILT_KERNEL := device/google/yogi-kernels/6.12/Image.lz4
TARGET_NO_BOOTLOADER := true

# Boot image header, read off the stock boot and init_boot rather than assumed.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

# vendor_boot is deliberately not built. Its ramdisk would need the device first-stage
# init and kernel modules, which are Google own and not among our blobs, so it comes out
# empty. Leaving it stock is proven: the DSU test booted a generic A17 system on yogi own
# vendor_boot, our kernel zip has always left it alone, and the installed recovery lives
# there.

# TODO: AVB. Stock boot is chained (vbmeta carries a chain descriptor for boot
# at rollback index location 2) and signed MLDSA65, which we cannot reproduce.
# Our own images are signed with the AOSP test key; decide how this tree signs.

# Policy from the shared Pixel tree, for the blobs this device actually ships. Each dir
# was picked by matching the paths its file_contexts labels against our blob list, not by
# guessing: citadel labels citadeld and citadel_updater, power-libperfmgr labels sendhint,
# sscoredump labels sscoredump.
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/vendor \
    hardware/google/pixel-sepolicy/citadel \
    hardware/google/pixel-sepolicy/power-libperfmgr \
    hardware/google/pixel-sepolicy/powerstats \
    hardware/google/pixel-sepolicy/sscoredump \
    hardware/google/pixel-sepolicy/lineage_health \
    hardware/google/pixel-sepolicy/powershare \
    hardware/google/pixel-sepolicy/touch \
    hardware/google/pixel-sepolicy/wifi_ext

# Reverse wireless charging. init.malibu.rc chowns this node to system, and the stock
# wireless_charger HAL drives the same one.
SOONG_CONFIG_NAMESPACES += lineage_powershare
SOONG_CONFIG_lineage_powershare += powershare_path
SOONG_CONFIG_lineage_powershare_powershare_path := /sys/class/power_supply/wireless/device/rtx

# dtbo. Stock's, from the B1 OTA -- we build no device tree of our own.
BOARD_PREBUILT_DTBOIMAGE := device/google/yogi-kernels/6.12/dtbo.img

# TODO: include $(VENDOR_PATH)/BoardConfigVendor.mk once blobs are extracted
