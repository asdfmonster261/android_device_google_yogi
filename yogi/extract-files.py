#!/usr/bin/env -S PYTHONPATH=../../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import blob_fixups_user_type
from extract_utils.fixups_lib import (
    lib_fixup_remove_arch_suffix,
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    "hardware/google/av",
    "hardware/google/interfaces",
    "hardware/google/pixel",
]

def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f"{lib}_{partition}" if partition == "vendor" else None

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        "com.google.hardware.pixel.display-V22-ndk",
        "hardware.google.ril_ext-V2-ndk",
        "pixel-power-ext-V1-ndk",
        "pixel-power-ext-V2-ndk",
        "com.google.hardware.pixel.display-V15-ndk",
        "google.hardware.image-V1-ndk",
        "libmedia_ecoservice",
        "com.google.edgetpu_app_service-V10-ndk",
        "com.google.edgetpu_vendor_service-V2-ndk",
        "libmipc",
        "libmtkproperty",
        "libmtkrillog",
        "libtrm",
        "vendor.google.whitechapel.audio.audioext@4.0",
        "vendor.google.whitechapel.audio.extension-V8-ndk",
    ): lib_fixup_vendor_suffix,
    (
        "libclang_rt.hwasan-arm-android",
        "libclang_rt.hwasan-aarch64-android",
    ): lib_fixup_remove_arch_suffix,
}

# Blob fixups are discovered during bring-up, not guessed up front.
blob_fixups: blob_fixups_user_type = {}

module = ExtractUtilsModule(
    "yogi",
    "google",
    device_rel_path="device/google/yogi/yogi",
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    # The per-carrier protobufs under product/etc/CarrierSettings. CarrierSettings only
    # reads them, so without the data the framework applies no carrier config at all and
    # every value falls back to its AOSP default, including carrier_volte_available_bool.
    add_generated_carriersettings_file=True,
)

module.add_generated_proprietary_file(
    "proprietary-files-vendor.txt",
    partition="vendor",
    skip_file_list_name="skip-files-vendor.txt",
)

if __name__ == "__main__":
    utils = ExtractUtils.device(module)
    utils.run()
