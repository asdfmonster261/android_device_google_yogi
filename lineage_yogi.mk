#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Book-style foldable with telephony, which is what yogi is.
$(call inherit-product, vendor/lineage/config/common_full_foldable_book_telephony.mk)

DEVICE_CODENAME := yogi
DEVICE_PATH := device/google/yogi
VENDOR_PATH := vendor/google/yogi
$(call inherit-product, $(DEVICE_PATH)/aosp_$(DEVICE_CODENAME).mk)

PRODUCT_NAME := lineage_$(DEVICE_CODENAME)
PRODUCT_SYSTEM_BRAND := google
PRODUCT_SYSTEM_MANUFACTURER := Google
PRODUCT_SYSTEM_NAME := generic_system_google

# Boot animation: the cover panel, which is what recovery and boot render on.
TARGET_SCREEN_HEIGHT := 2342
TARGET_SCREEN_WIDTH := 1080
