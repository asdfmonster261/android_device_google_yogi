#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_CODENAME := yogi
DEVICE_PATH := device/google/yogi
VENDOR_PATH := vendor/google/yogi

$(call inherit-product, device/google/malibu/aosp_common.mk)
$(call inherit-product, $(DEVICE_PATH)/device-yogi.mk)

PRODUCT_NAME := aosp_yogi
PRODUCT_DEVICE := yogi
PRODUCT_MODEL := Pixel 11 Pro Fold
PRODUCT_BRAND := google
PRODUCT_MANUFACTURER := Google

PRODUCT_NAME_FOR_ATTESTATION := yogi
PRODUCT_DEVICE_FOR_ATTESTATION := yogi
PRODUCT_MODEL_FOR_ATTESTATION := Pixel 11 Pro Fold
PRODUCT_BRAND_FOR_ATTESTATION := google
PRODUCT_MANUFACTURER_FOR_ATTESTATION := Google
