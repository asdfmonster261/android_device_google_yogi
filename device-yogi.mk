#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Kernel. Prebuilt to begin with, which is what LineageOS does for Pixels
# (comet points at a comet-kernels repo). Ours comes from heybooboo-kernel,
# ACK android16-6.12 with our patches, already proven to boot this device.
TARGET_LINUX_KERNEL_VERSION := 6.12
TARGET_KERNEL_DEVICE := yogi
TARGET_KERNEL_DIR := device/google/$(TARGET_KERNEL_DEVICE)-kernels/$(TARGET_LINUX_KERNEL_VERSION)
# TODO: stage the prebuilt Image/dtbo/modules into that directory.

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm \
    vendor_kernel_boot

PRODUCT_PACKAGES += \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

# Device is a book-style foldable: two panels, hinge sensor.
# TODO: overlays for display/hinge once the tree boots.

# TODO: HALs, fstab install, init scripts, sepolicy, vendor blob makefiles.
# Everything below the line is deliberately absent until it is derived from
# the B1 dump rather than copied from another device.

# Dynamic partitions (product-side; BoardConfig cannot set PRODUCT_* vars).
PRODUCT_USE_DYNAMIC_PARTITIONS := true
