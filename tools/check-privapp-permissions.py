#!/usr/bin/env python3
# Report priv-apps that request a privileged permission nothing allowlists.
#
# ro.control_privapp_permissions is enforce on this product, and in that mode the first
# priv-app holding a signature|privileged permission with no allowlist entry throws
# IllegalStateException out of system_server during boot. Nothing in the build fails, so
# the image looks fine and then bootloops on the device.
#
# Platform-signed apps are usually fine because they qualify by signature, but the check
# runs anyway (AppIdPermissionPolicy evaluates mayGrantByPrivileged before the signature
# test), and a presigned vendor blob cannot qualify by signature at all. Those are the
# ones this catches.
#
# Permissions carrying android:featureFlag are skipped. They are not defined at runtime
# unless the flag is on, so they cannot be allowlisted and reporting them is noise.
#
# Run after a build, from anywhere in the tree. Exits non-zero if anything is missing.

import glob
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

top = os.environ.get('ANDROID_BUILD_TOP')
out = os.environ.get('ANDROID_PRODUCT_OUT')
host = os.environ.get('ANDROID_HOST_OUT')
if not top or not out:
    sys.exit('lunch first: ANDROID_BUILD_TOP and ANDROID_PRODUCT_OUT are unset')
aapt2 = os.path.join(host or os.path.join(top, 'out/host/linux-x86'), 'bin/aapt2')
if not os.path.exists(aapt2):
    sys.exit('no aapt2 at %s, build first' % aapt2)

PARTITIONS = ('system', 'system_ext', 'product', 'vendor', 'odm')

manifest = os.path.join(top, 'frameworks/base/core/res/AndroidManifest.xml')
with open(manifest, encoding='utf-8', errors='replace') as f:
    platform = f.read()

privileged = set()
for m in re.finditer(r'<permission\b[^>]*?>', platform, re.S):
    tag = m.group(0)
    if 'android:featureFlag' in tag:
        continue
    name = re.search(r'android:name="([^"]+)"', tag)
    level = re.search(r'android:protectionLevel="([^"]+)"', tag)
    if name and level and 'privileged' in level.group(1):
        privileged.add(name.group(1))

allowlist = {}
for part in PARTITIONS:
    for d in ('etc/permissions', 'etc/sysconfig'):
        for path in glob.glob(os.path.join(out, part, d, '*.xml')):
            try:
                root = ET.parse(path).getroot()
            except ET.ParseError:
                continue
            for entry in root.iter('privapp-permissions'):
                package = entry.get('package')
                if not package:
                    continue
                names = allowlist.setdefault(package, set())
                for child in entry:
                    # deny-permission is deliberately not collected: it denies rather
                    # than allowlists, so treating it as one would hide a violation
                    if child.tag == 'permission' and child.get('name'):
                        names.add(child.get('name'))

violations = []
for part in PARTITIONS:
    for apk in sorted(glob.glob(os.path.join(out, part, 'priv-app/*/*.apk'))):
        dump = subprocess.run([aapt2, 'dump', 'permissions', apk],
                              capture_output=True, text=True).stdout
        package = re.search(r'^package: (\S+)', dump, re.M)
        package = package.group(1) if package else os.path.basename(apk)
        wanted = set(re.findall(r"^uses-permission: name='([^']+)'", dump, re.M))
        missing = sorted((wanted & privileged) - allowlist.get(package, set()))
        if missing:
            violations.append((package, os.path.relpath(apk, out), missing))

if not violations:
    print('ok: every priv-app is allowlisted for the privileged permissions it requests')
    sys.exit(0)

print('these throw IllegalStateException out of system_server on boot:')
for package, path, missing in violations:
    print('  %s (%s)' % (package, path))
    for name in missing:
        print('      %s' % name)
sys.exit(1)
