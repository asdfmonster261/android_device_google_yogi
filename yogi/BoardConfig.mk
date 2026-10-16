#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# yogi (Pixel 11 Pro Fold); the shared family config is in device/google/malibu.

TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_BOOTLOADER_BOARD_NAME := yogi
TARGET_SCREEN_DENSITY := 420

MALIBU_KERNEL_DIR := device/google/yogi-kernels/6.12

include device/google/malibu/BoardConfig-common.mk

# Without the multidisplay flag the boot animation draws on one panel only.
$(call soong_config_set_bool,bootanimation,multidisplay,true)

include $(VENDOR_PATH)/BoardConfigVendor.mk
