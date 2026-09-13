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
    vendor_dlkm

# The LineageOS HALs this device can serve. touch uses the pixel implementation rather
# than the default one, since the touch driver is Google's. That implementation lives in
# a soong namespace, so the namespace has to be declared for PRODUCT_PACKAGES to find it.
PRODUCT_SOONG_NAMESPACES += \
    hardware/google/pixel

PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default \
    vendor.lineage.powershare-service.default \
    vendor.lineage.touch-service.pixel

PRODUCT_PACKAGES += \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

# Recovery lives in the stock vendor_boot, which this tree does not build, so there is
# no recovery image and nothing assigns recovery_fstab -- the OTA package is gated on it
# and would silently not be built, leaving bacon to link a file that was never produced.
PRODUCT_BUILD_GENERIC_OTA_PACKAGE := true

# Vendor AIDs.
TARGET_FS_CONFIG_GEN += $(DEVICE_PATH)/config.fs

# VINTF. All of this is stock yogi own, from the B1 vendor image, since the HALs we ship
# are the device own. The four fragments Google keeps under etc/vintf/manifest/ are
# merged in here rather than installed separately: their module names are taken by HALs
# the tree builds itself, and VINTF metadata cannot go through PRODUCT_COPY_FILES.
DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/vintf/manifest.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.thermal-service.pixel.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/gnss-default.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/nfc2-service-default.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/pixel-display-default.xml

# Device framework compatibility matrices. The manifest declares vendor HALs that no
# AOSP framework matrix knows about (the MediaTek radio ones above all), so the device
# has to declare them. These are stock yogi own, from the B1 system_ext image, which is
# where Google ships them.
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/vintf/radio_framework_matrix_system_ext.xml \
    $(DEVICE_PATH)/vintf/aocx_framework_matrix_system_ext.xml \
    $(DEVICE_PATH)/vintf/camera_interference_avoidance_framework_matrix_system_ext.xml \
    $(DEVICE_PATH)/vintf/imageprocessing_hal_framework_matrix_system_ext.xml

DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/vintf/device_framework_matrix_product.xml

# Our kernel deliberately deviates from two of AOSP kernel config requirements:
# CONFIG_SYSVIPC=y, which the Linux container work needs and which shipped with a
# kABI patch so it is CRC-neutral, and CONFIG_IP6_NF_NAT=y. Both are required to be
# n at FCM level 202504, so the OTA kernel requirement check cannot pass. It gates
# GMS compliance rather than function, and the kernel is device-verified.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Device is a book-style foldable: two panels, hinge sensor.
# TODO: overlays for display/hinge once the tree boots.

# TODO: HALs, fstab install, init scripts, sepolicy, vendor blob makefiles.
# Everything below the line is deliberately absent until it is derived from
# the B1 dump rather than copied from another device.

# Dynamic partitions (product-side; BoardConfig cannot set PRODUCT_* vars).
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Virtual A/B with compression. Values measured from the B1 OTA payload manifest
# (vabc_enabled=1, cow_version=3, vabc_compression_param=lz4), which also matters for
# partition sizing: super holds one copy on virtual A/B, not two.
PRODUCT_VIRTUAL_AB_OTA := true
PRODUCT_VIRTUAL_AB_COMPRESSION := true
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4
PRODUCT_VIRTUAL_AB_COW_VERSION := 3

# Do not build vendor_boot (and so not vendor_kernel_boot, which requires it). A boot
# header version of 3 or more would otherwise imply one, and its ramdisk would come out
# empty: the device first-stage init and kernel modules are Google own and are not among
# our blobs. The device keeps its own, which the DSU test proved boots a generic A17
# system, and which is also where the installed recovery lives.
PRODUCT_BUILD_VENDOR_BOOT_IMAGE := false
