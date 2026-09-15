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

# Sign with our own keys instead of AOSP's testkey, which every AOSP tree ships and whose
# private half is public. That is what ro.build.tags reports, and it is the last thing the
# Trust page still flags: config.mk maps a certificate under vendor/lineage-priv/ to
# release-keys, anything else outside AOSP's own directory to dev-keys, and the AOSP testkey
# to test-keys.
#
# The keys live outside this repository on purpose. vendor/lineage-priv is not a repo project
# and nothing tracks it, so a private key cannot be committed by accident. It also means the
# tree does not build without them: generate a set with development/tools/make_key before the
# first build on a new machine.
#
# Changing this re-signs every platform-signed app, so their signatures no longer match what
# an installed copy was signed with. Installing over existing data needs a wipe.
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey

# The extracted blobs. This has to come after the inherits above, since it appends to
# PRODUCT_PACKAGES and PRODUCT_COPY_FILES.
$(call inherit-product, $(VENDOR_PATH)/$(DEVICE_CODENAME)-vendor.mk)
