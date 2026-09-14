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

# Two logical slots by default, which is what makes the eSIM reachable. This device has a
# physical tray and a non-removable eUICC, but the framework sizes its phone count from
# persist.radio.multisim.config, and on a fresh /data that is empty, which means one logical
# slot. The single slot goes to the tray, the eUICC port is left unmapped, and the profile
# list never reaches SubscriptionManagerService: no subscription, no service, and a slot
# remapping that silently reverts because there is nowhere to put it. The framework only
# writes this property itself once something calls switchMultiSimConfig, so without a default
# a clean install has no mobile service until the user knows to enable dual SIM by hand.
#
# Both HAL slot instances register and the vendor side advertises two SIMs
# (ro.vendor.mtk_sim_card_onoff=3, persist.vendor.radio.mtk_dsbp_support=3,
# telephony.active_modems.max_count=2), so this matches the hardware rather than forcing it.
# A value persisted in /data still wins, so this only supplies the initial state.
PRODUCT_SYSTEM_PROPERTIES += \
    persist.radio.multisim.config=dsds

# Framework resources. Recovered from the vendor overlay the stock build ships, which
# the blob list drops because it is an auto_generated_rro carrying the codename. Nothing
# replaced it, so all 190 values fell back to the AOSP defaults, and two of those are
# load-bearing. config_num_physical_slots defaults to 1 while RIL reports physical slot 1,
# which throws out of UiccController, kills com.android.phone, and takes rild and then the
# modem down with it about every six seconds. config_displayUniqueIdArray is how the
# framework tells the inner panel from the cover one. Note the usual fallback that would
# have hidden the slot bug, raising numPhysicalSlots to the phone count, is skipped on
# anything launched after VENDOR_API_2024_Q2, so this device gets no safety net.
#
# Shipped as an RRO rather than compiled in with DEVICE_PACKAGE_OVERLAYS. A static overlay
# only reaches packages this tree builds, so it cannot express an override for anything
# installed later, and an unmatched resource name is ADDED to the target rather than
# ignored. An RRO installs as its own apk, stays dormant with no idmap while its target is
# absent, and binds automatically if the target appears.
#
# The rest are the same recovery for the other targets stock overlays. The product
# framework-res one carries the fold state machine (config_foldedDeviceStates, the hinge
# in config_display_features, the posture map) and the large-screen letterbox config;
# TeleService carries emergency call routing and RTT; SettingsProvider carries the screen
# timeout and satellite-mode defaults. Each is filtered to names the target actually
# declares, since Google builds these against its own packages and the surplus would
# never idmap. Priorities are stock own: vendor 0, product 1, so product wins.
PRODUCT_PACKAGES += \
    FrameworkResOverlayVendorYogi \
    FrameworkResOverlayProductYogi \
    SystemUIGoogleOverlayVendorYogi \
    SystemUIGoogleOverlayProductYogi \
    SettingsGoogleOverlayVendorYogi \
    SettingsGoogleOverlayProductYogi \
    TeleServiceOverlayVendorYogi \
    TeleServiceOverlayProductYogi \
    SettingsProviderOverlayVendorYogi \
    SettingsProviderOverlayProductYogi \
    FrameworkResOverlayLineageYogi \
    LineageSdkOverlayYogi

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

# IMS, which is what voice calls go over. ImsStack implements
# android.telephony.ims.ImsService and Iwlan is the same for calling over wifi; both
# are built from source and bring their own permissions and sysconfig, but no product
# was requesting them, so nothing implemented ImsService and the framework never
# registered IMS. SMS and data were unaffected because SMS rides the CS domain.
PRODUCT_PACKAGES += \
    ImsStack \
    Iwlan

# The wifi daemons and the supplicant config template. BoardConfig-wifi.mk decides how they
# are built; these install them. wpa_supplicant.conf is not optional: the supplicant copies
# it to /data on first use, and with no template anywhere addStaInterface fails outright, so
# wifi never turns on.
PRODUCT_PACKAGES += \
    hostapd \
    wpa_supplicant \
    wpa_supplicant.conf

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

# EuiccPolicy feeds partner customisation to the LPA and disables Google's one when
# GMS is absent, so it is what decides which LPA serves. LineageOS ships it but no
# product pulls it in, since it only makes sense on a device that has an eUICC.
PRODUCT_PACKAGES += \
    EuiccPolicy

# EuiccGoogle is presigned, so it cannot pick up a signature|privileged permission by
# signature the way a platform-signed app does, and stock keeps its allowlist in a gms
# file. With ro.control_privapp_permissions=enforce the first missing entry throws out
# of system_server on boot, so it needs one of its own.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/permissions/privapp-permissions-google-euicc.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-google-euicc.xml \
    $(DEVICE_PATH)/permissions/privapp-permissions-google-carrier.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-google-carrier.xml

# The embedded secure element behind ISecureElement/eSE1. Built from source; its
# libse-gto-hal.conf is already among the blobs.
PRODUCT_PACKAGES += \
    android.hardware.secure_element-service.thales

# OpenEUICC is the LPA for anyone not running GMS. It declares a lower intent-filter
# priority than Google's, so where both are enabled the stock one serves and this takes
# over when EuiccPolicy disables it.
PRODUCT_PACKAGES += \
    OpenEUICC

# eSIM. The eUICC sits behind ISecureElement/SIM1, so an LPA needs the OMAPI UICC
# reader and EuiccManager exposed. Stock keeps the OMAPI declaration in vendor and the
# telephony ones in product.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.uicc.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.ese.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.ese.xml \
    frameworks/native/data/etc/android.hardware.telephony.euicc.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.telephony.euicc.xml \
    frameworks/native/data/etc/android.hardware.telephony.euicc.mep.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.telephony.euicc.mep.xml

# Libraries the vendor partition hands to apex namespaces. The camera HAL runs from an apex
# with namespace mnt, so it sees only what this grants, and libgoog_catpipe dlopens the gxp
# and edgetpu accelerators for computational photography. Stock ships a linker.config.pb
# carrying these six names; the blob list drops it and the tree generates an empty one, so
# every dlopen failed, the provider dereferenced the null it got back and crash-looped, and
# the framework saw zero cameras. public.libraries.txt lists them too but does not cover an
# apex namespace on its own.
PRODUCT_VENDOR_LINKER_CONFIG_FRAGMENTS += $(DEVICE_PATH)/linker.config.json

# Vendor AIDs.
TARGET_FS_CONFIG_GEN += $(DEVICE_PATH)/config.fs

# VINTF. All of this is stock yogi own, from the B1 vendor image, since the HALs we ship
# are the device own. Five of the fragments Google keeps under etc/vintf/manifest/ are
# merged in here rather than installed separately. For the first four the module name is
# taken by a HAL the tree builds itself, and VINTF metadata cannot go through
# PRODUCT_COPY_FILES. pixel-display-secondary is here to keep it beside its sibling:
# the composer registers both IDisplay instances and CHECKs the addService status, so
# dropping either declaration aborts it and takes surfaceflinger down with it.
DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/vintf/manifest.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.thermal-service.pixel.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/gnss-default.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/nfc2-service-default.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/pixel-display-default.xml \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/pixel-display-secondary.xml

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

# Virtual A/B with compression. Setting the flags alone declares it without shipping any
# of it: snapuserd serves the compressed cow, and first_stage_init prefers the generic
# ramdisk copy because that side of treble gets updated with the platform. generic_ramdisk
# supplies that copy (plus init_first_stage and toolbox_ramdisk, which is why our generic
# ramdisk was 13 entries against stock's 37), and compression_with_xor supplies the vendor
# ramdisk fsck and linker binaries and every ro.virtual_ab property stock reports. Pixels
# get both from a soc-common tree that has no malibu equivalent, so they are named here.
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)

# Measured from the B1 OTA payload manifest; the makefiles above leave both unset.
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4
PRODUCT_VIRTUAL_AB_COW_VERSION := 3

# Recovery. There is no recovery partition on this device, so it rides in vendor_boot.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/recovery/init.recovery.device.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.yogi.rc \
    $(DEVICE_PATH)/recovery/init.recovery.malibu.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.malibu.rc

# The first-stage fstab, byte-identical to the copy in stock's vendor_boot, so it is
# taken from the blob rather than duplicated where the two could drift apart.
PRODUCT_COPY_FILES += \
    $(VENDOR_PATH)/proprietary/vendor/etc/fstab.malibu:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/system/etc/fstab.malibu


# Two services ship as blobs whose init rc never lands. The rc path is owned by a tree
# module's init_rc, which is enough for kati to call it a duplicate recipe, so the blob rc
# went in the skip list, but the module is not selected either, so its rule never runs. The
# binary installs and nothing ever starts it. Selecting the module installs both halves, and
# both tree rcs are byte-identical to the ones stock ships.
#
# vndservicemanager is the one that blocks boot: with no context manager on /dev/vndbinder,
# citadeld and the citadel strongbox keymint can never register, and keystore2 will not
# continue without sending module info to every declared KeyMint security level.
PRODUCT_PACKAGES += \
    vndservicemanager \
    rebalance_interrupts-vendor

# The device module-load config. insmod_sh_yogi runs insmod.sh against this file
# (init.yogi.rc:28). What it is really for is the three properties it sets,
# vendor.device.modules.ready / vendor.all.modules.ready / vendor.all.devices.ready, which
# gate large on-property blocks in init.yogi.rc and init.malibu.rc. One of those blocks
# enables the vibrator HAL, so with the file absent system_server waits on
# IVibratorManager forever. Its modprobe lines are redundant here, measured: all five
# modules load anyway because vendor_dlkm modules.load already names them. It lives in
# vendor_dlkm, not vendor, so the blob list does not reach it.
PRODUCT_COPY_FILES += \
    device/google/yogi/init.insmod.yogi.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/etc/init.insmod.yogi.cfg

# Vendor properties recovered from stock. See the header in that file for why the gap
# mattered: without ro.hardware.egl there is no display at all.
include device/google/yogi/vendor_props.mk
