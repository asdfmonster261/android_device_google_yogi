#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# TODO: once a malibu SoC-common tree exists this should inherit
# device/google/malibu/aosp_common.mk, the way comet inherits zumapro.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, device/google/yogi/device-yogi.mk)

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
