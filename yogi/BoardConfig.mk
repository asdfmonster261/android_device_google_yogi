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

# This deliberately does NOT match PLATFORM_SECURITY_PATCH, which the aosp tag puts two
# quarters earlier, and the gap is not a bug to close. Raising the platform one to agree
# would claim aosp patches this tree does not carry. Lowering this one is the direction
# that costs /data, and it also feeds BOARD_AVB_ROLLBACK_INDEX below, which has to stay
# at stock's value. The only cost of the split is that /data must be wiped on install,
# because keymint binds keys to the platform level and the older one cannot unwrap keys
# minted under the newer. That is standard practice for a rom install anyway. None of
# this touches bootloader anti-rollback, which keys off partitions this build never
# writes.

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
# The version is inert on its own: init_boot gets BOARD_MKBOOTIMG_INIT_ARGS, not
# BOARD_MKBOOTIMG_ARGS, so without this line mkbootimg defaults to a v0 header and the
# bootloader rejects the image before it reaches the kernel.
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

# Zero os_version in the boot header, which is what stock does here and what a working
# Pixel 11 rom does. The build hardcodes it from PLATFORM_SECURITY_PATCH, which would claim
# a patch level below the one the device last ran, and it disagrees with the security_patch
# in our own avb footer. mkbootimg's parsers return 0 for anything non-numeric, and these
# land after the internal args so they win. init_boot is deliberately left alone: stock and
# the reference rom both populate it there.
BOARD_MKBOOTIMG_ARGS += --os_version none --os_patch_level none

# The vendor_boot cmdline and bootconfig, read off stock. Leaving these unset builds a
# vendor_boot with an empty header, and the one that matters is boot_devices: first-stage
# init resolves /dev/block/by-name through it, so without it no partition is found, system
# never mounts and the bootloader bounces straight back with no retry consumed. The rest is
# driver load ordering and android_arch_task_struct_size, which the vendor modules assert
# against. dyndbg is quoted for the shell because the build wraps this in double quotes.
BOARD_KERNEL_CMDLINE := spmi_smartdv.load_sequential=1 regmap-goog-spmi.load_sequential=1
BOARD_KERNEL_CMDLINE += max77779_pmic.load_sequential=1 max77779_pmic_spmi.load_sequential=1
BOARD_KERNEL_CMDLINE += max77779_pmic_pinctrl.load_sequential=1
BOARD_KERNEL_CMDLINE += samsung_dma_heap.gcma_skip_heaps=gcma_camera_internal
BOARD_KERNEL_CMDLINE += dyndbg=\"func alloc_contig_dump_pages +p\"
BOARD_KERNEL_CMDLINE += cma_sysfs.experimental=Y init_on_alloc=0 init_on_free=1
BOARD_KERNEL_CMDLINE += rcupdate.rcu_expedited=1 rcu_nocbs=all rcutree.enable_rcu_lazy
BOARD_KERNEL_CMDLINE += swiotlb=noforce disable_dma32=on rodata=on
BOARD_KERNEL_CMDLINE += sysctl.kernel.sched_pelt_multiplier=4 arm64.nomops
BOARD_KERNEL_CMDLINE += aoc_core.aoc_panic_on_ssr_failure=1 aoc_core.aoc_enable_gsa_boot=1
BOARD_KERNEL_CMDLINE += ufs.async_probe=1 vs_drm.async_probe=1 gs_governor_dsulat.async_probe=1
BOARD_KERNEL_CMDLINE += arm64.nosme kasan=off at24.write_timeout=100 log_buf_len=1024K
BOARD_KERNEL_CMDLINE += android_arch_task_struct_size=784 bootconfig

BOARD_BOOTCONFIG := androidboot.load_modules_parallel=performance
BOARD_BOOTCONFIG += androidboot.boot_devices=3c2d0000.ufs

# TEMPORARY, for bring-up only. Remove once sepolicy/vendor carries the device policy.
# Without it init refuses to start any vendor hal: the binaries land as plain vendor_file
# because our file_contexts has 2 entries against stock's 665, so there is no domain for
# init to transition into and ComputeContextFromExecutable errors out. That check only
# aborts when enforcing (init/service.cpp), so permissive lets the 83 affected services
# run and produces the avc denials the real policy has to be written against.
BOARD_BOOTCONFIG += androidboot.selinux=permissive

# DIAGNOSTIC, remove with the permissive flag. init's fatal signal handler reboots to
# init_fatal_reboot_target, which defaults to bootloader -- that is what "enter reason:
# reboot bootloader" means, and it takes the crash log with it because the bootloader
# overwrites the console ramoops region on the way through. With this, init triggers
# sysrq-c instead, so the backtrace lands in the dmesg ramoops region, which survives.
BOARD_BOOTCONFIG += androidboot.init_fatal_panic=true

# vendor_boot, which on this device also carries recovery: there is no recovery partition.
# An earlier note here said its ramdisk would need device kernel modules we do not have.
# That was wrong. Stock's is 530 entries of first-stage userspace and zero .ko, because
# the modules live in vendor_kernel_boot, a separate partition this build still leaves
# alone. Everything device-specific in it is an fstab and two init rc files.
BOARD_BUILD_VENDOR_RAMDISK_IMAGE := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864

# The recovery fstab is not the first-stage one: it drops inlinecrypt and asks for plain
# aes-256-xts with no wrapped key or metadata encryption, because recovery cannot use the
# hardware-wrapped key path. Stock ships exactly this split, and other Pixels generate the
# same thing under a name that says so (gen_fstab.<soc>-sw-encrypt).
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/recovery.fstab

# RGBX, not the ABGR every other Pixel sets. minui draws RGBA8888 under ABGR and this
# panel comes back with red and blue swapped, which is how orange renders blue. The
# recovery work on this device hit it and landed here.
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# AVB. Read off the stock B1 vbmeta: boot, init_boot, vbmeta_system and vbmeta_vendor
# are chained at rollback index locations 2, 4, 1 and 3, everything else carries a hash
# or hashtree descriptor in the main vbmeta. Signed MLDSA65, which is what stock uses --
# the key is ours rather than Google's, so the signature buys nothing on an unlocked
# bootloader, but the images then match stock's structure down to the algorithm type.
# Needs openssl 3.5 or newer on the build host: avbtool delegates ML-DSA to it.
BOARD_AVB_ENABLE := true

# Disable verification and hashtree checking in the top-level vbmeta. Our vbmeta is signed
# with a key the bootloader does not trust, and this bootloader reports
# avb-hastree-error-mode:restart, so with verification on it restarts rather than boots and
# the only symptom is "boot failure" at the bootloader. AOSP only adds the flag for eng
# builds, so a userdebug build has to ask. Measured against a working Pixel 11 rom, which
# ships flags=3 where ours shipped 0.
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_ALGORITHM := MLDSA65
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_mldsa65.pem

# Stock's rollback index is the security patch date as a Unix epoch, so deriving it from
# BOOT_SECURITY_PATCH reproduces stock's 1788220800 exactly. Do not lower it: a rollback
# index or patch level below what the device recorded is the direction that costs /data.
BOARD_AVB_ROLLBACK_INDEX := $(shell date -u -d "$(BOOT_SECURITY_PATCH)" +%s)

BOARD_AVB_BOOT_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(BOARD_AVB_ROLLBACK_INDEX)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_INIT_BOOT_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_INIT_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_INIT_BOOT_ROLLBACK_INDEX := $(BOARD_AVB_ROLLBACK_INDEX)
BOARD_AVB_INIT_BOOT_ROLLBACK_INDEX_LOCATION := 4

BOARD_AVB_VBMETA_SYSTEM := system system_ext product system_dlkm
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(BOARD_AVB_ROLLBACK_INDEX)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_VENDOR := vendor
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(BOARD_AVB_ROLLBACK_INDEX)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 3

# avbtool defaults a hashtree to sha1. Stock uses sha256 on every one of them.
BOARD_AVB_SYSTEM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_SYSTEM_EXT_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_PRODUCT_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_SYSTEM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_VENDOR_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_VENDOR_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256

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

# Loadable modules. vendor_dlkm is stock's -- those are built from private/, which no
# public tree has. system_dlkm is from our own kernel build, so the GKI modules match
# the kernel they load against. system_dlkm gets no load list on purpose: the build
# defaults that to false so GKI modules load only when a vendor module pulls them in.
KERNEL_MODULE_DIR := device/google/yogi-kernels/6.12

BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(KERNEL_MODULE_DIR)/vendor_dlkm/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := \
    $(addprefix $(KERNEL_MODULE_DIR)/vendor_dlkm/,\
        $(shell cat $(KERNEL_MODULE_DIR)/vendor_dlkm.modules.load 2>/dev/null))

BOARD_SYSTEM_KERNEL_MODULES := \
    $(wildcard $(KERNEL_MODULE_DIR)/system_dlkm/*.ko)

include $(DEVICE_PATH)/wifi/BoardConfig-wifi.mk

include $(VENDOR_PATH)/BoardConfigVendor.mk
