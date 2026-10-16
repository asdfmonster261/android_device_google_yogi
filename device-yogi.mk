#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# yogi (Pixel 11 Pro Fold); the shared family config is in device/google/malibu.

# Prebuilt; the Image is the family build, vendor_dlkm and dtbo are the fold's own.
TARGET_LINUX_KERNEL_VERSION := 6.12
TARGET_KERNEL_DEVICE := yogi
TARGET_KERNEL_DIR := device/google/$(TARGET_KERNEL_DEVICE)-kernels/$(TARGET_LINUX_KERNEL_VERSION)

# Recovered from the stock overlays the blob list drops; priorities are stock's own,
# vendor 0 and product 1. config_num_physical_slots and config_displayUniqueIdArray are
# load-bearing, see the working notes.
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
    LineageSdkOverlayYogi \
    SettingsOverlayLineageYogi

# config_face_enroll points Settings here; the HAL draws the preview itself.
PRODUCT_PACKAGES += \
    FaceEnroll

# The composer CHECKs addService for both IDisplay instances; dropping either aborts it.
DEVICE_MANIFEST_FILE += \
    $(VENDOR_PATH)/proprietary/vendor/etc/vintf/manifest/pixel-display-secondary.xml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.hinge_angle.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hinge_angle.xml

# The three vendor.*.modules/devices.ready properties gate the init blocks incl. the
# vibrator HAL; without them system_server waits on IVibratorManager forever.
PRODUCT_COPY_FILES += \
    device/google/yogi/init.insmod.yogi.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/etc/init.insmod.yogi.cfg

# Without ro.hardware.egl there is no display.
include device/google/yogi/vendor_props.mk
