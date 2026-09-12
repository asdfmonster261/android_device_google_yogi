#!/usr/bin/env -S PYTHONPATH=../../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import blob_fixups_user_type
from extract_utils.fixups_lib import (
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
        "com.google.edgetpu_app_service-V10-ndk",
        "com.google.edgetpu_vendor_service-V2-ndk",
        "libmipc",
        "libmtkproperty",
        "libmtkrillog",
        "libtrm",
        "vendor.google.whitechapel.audio.audioext@4.0",
        "vendor.google.whitechapel.audio.extension-V8-ndk",
    ): lib_fixup_vendor_suffix,
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
)

module.add_generated_proprietary_file(
    "proprietary-files-vendor.txt",
    partition="vendor",
    skip_file_list_name="skip-files-vendor.txt",
)

if __name__ == "__main__":
    utils = ExtractUtils.device(module)
    utils.run()
