#!/usr/bin/env -S PYTHONPATH=../../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_files import module
from extract_utils.main import ExtractUtils

if __name__ == "__main__":
    utils = ExtractUtils.device_with_common(module)
    utils.run()
