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

# Vulkan and the deqp conformance levels. The source files are version suffixed and
# stock installs them under the plain name, so these are matched to stock by the
# feature version they declare rather than by filename.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_4.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2026-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-latest.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# Hardware capability declarations. handheld_core_hardware.xml only covers the AOSP
# baseline, so without these the framework reports no wifi, no GPS, no gyroscope, no
# multitouch and no fingerprint, and the Play Store filters on exactly that. The set
# is stock's own filenames, minus what we already declare.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.channel_sounding.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.channel_sounding.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml \
    frameworks/native/data/etc/android.hardware.context_hub.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.context_hub.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.dynamic.head_tracker.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.hifi_sensors.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hifi_sensors.xml \
    frameworks/native/data/etc/android.hardware.sensor.hinge_angle.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hinge_angle.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.telephony.carrierlock.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.carrierlock.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.rtt.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.rtt.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnel_migration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnel_migration.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml \
    frameworks/native/data/etc/android.hardware.biometrics.face.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.biometrics.face.xml

# NFC. The HAL, its configs and the NFC apex were already being built; without these
# four declarations the framework does not enable NFC at all. hce is what card emulation
# payments use, hcef is the NFC-F variant, ese is for cards held in the secure element.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/android.hardware.nfc.ese.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.ese.xml

PRODUCT_PACKAGES += \
    com.android.nfc_extras

# The wifi daemons. BoardConfig-wifi.mk decides how they are built; these install them.
PRODUCT_PACKAGES += \
    hostapd \
    wpa_supplicant

# HAL services this tree builds but nothing installed. The default KeyMint is the one
# that matters most: FBE key derivation goes through it, and only the strongbox instance
# was present. Gatekeeper verifies lockscreen credentials, and without the sensors
# multihal the device has no sensors at all.
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service.rust.trusty \
    android.hardware.gatekeeper-service.trusty \
    android.hardware.security.secretkeeper.trusty \
    android.hardware.sensors-service.multihal \
    android.hardware.drm-service.clearkey

# system_ext declares the computercontrol extension by name, so the declaration points
# at a missing jar unless the library is installed too.
PRODUCT_PACKAGES += \
    com.android.extensions.computercontrol

# The embedded secure element behind ISecureElement/eSE1. Built from source; its
# libse-gto-hal.conf is already among the blobs.
PRODUCT_PACKAGES += \
    android.hardware.secure_element-service.thales

# eSIM. The eUICC sits behind ISecureElement/SIM1, so an LPA needs the OMAPI UICC
# reader and EuiccManager exposed. Stock keeps the OMAPI declaration in vendor and the
# telephony ones in product.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.uicc.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.ese.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.ese.xml \
    frameworks/native/data/etc/android.hardware.telephony.euicc.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.telephony.euicc.xml \
    frameworks/native/data/etc/android.hardware.telephony.euicc.mep.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.telephony.euicc.mep.xml

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
