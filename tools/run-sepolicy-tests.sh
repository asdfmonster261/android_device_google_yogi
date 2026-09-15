#!/bin/bash
# Run AOSP's sepolicy_tests suite against the policy this build produced.
#
# Naming sepolicy_tests as a build target is not enough to run it. It is a python_binary_host,
# so building it only compiles the tool. And the suite splits in two, which is easy to miss:
# sepolicy_tests.py ends with
#
#     # dev type test won't be run as default
#     if options.test and "TestDevTypeViolations" in options.test:
#
# so a bare invocation runs fourteen checks and silently skips the /dev one, while the genrule
# sepolicy_dev_type_test passes -t TestDevTypeViolations and so runs only that. Neither half
# covers the other. This runs both.
#
# What the fourteen cover: /vendor, /proc, /sys, /data, debugfs and tracefs paths carry the
# right type attribute, no property is claimed by two partitions, domains launched from
# /system carry coredomain, app_data_file types are reached only through seapp_contexts, and
# isolated_app cannot reach past its allowlist.
#
# Run from the tree root after a build. Exits non-zero if the policy violates anything.
set -uo pipefail
P=out/target/product/yogi
T=out/soong/.intermediates/system/sepolicy/tests/sepolicy_tests/linux_glibc_x86_64/sepolicy_tests

[ -x "$T" ] || { echo "sepolicy_tests not built; add it to the m line"; exit 2; }
[ -f "$P/vendor/etc/selinux/precompiled_sepolicy" ] || { echo "no built policy at $P"; exit 2; }

FC=(-f "$P/system/etc/selinux/plat_file_contexts"
    -f "$P/vendor/etc/selinux/vendor_file_contexts"
    -f "$P/system_ext/etc/selinux/system_ext_file_contexts"
    -f "$P/product/etc/selinux/product_file_contexts")

fail=0
run() {   # run <label> [extra args]
  local label="$1"; shift
  local out rc real
  out=$("$T" "${FC[@]}" -p "$P/vendor/etc/selinux/precompiled_sepolicy" "$@" 2>&1); rc=$?
  # The policy library prints this once per lookup whether or not anything is wrong, and it
  # buries the real output. It is not a finding.
  real=$(printf "%s\n" "$out" | grep -v "isolated_compute_allowed_property_type" | grep -v "^$")
  if [ $rc -ne 0 ] || [ -n "$real" ]; then
    echo "  $label FAILED (exit $rc)"
    printf "%s\n" "$real"
    fail=1
  else
    echo "  $label OK"
  fi
}

echo "sepolicy_tests:"
run "default checks (14)"
run "/dev label check" -t TestDevTypeViolations
exit $fail
