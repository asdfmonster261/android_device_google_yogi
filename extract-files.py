#!/bin/bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
set -e
MY_DIR="$(cd "$(dirname "${0}")"; pwd -P)"
pushd "${MY_DIR}/yogi"
./extract-files.py $@
popd
