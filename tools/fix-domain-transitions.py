#!/usr/bin/env python3
"""Give each domain the transition source stock gives it.

The bring-up generator wrote init_daemon_domain() for every device domain, which is
right for a service init starts and wrong for anything else. A domain whose parent is
not init then never transitions: the parent executes the binary with no transition, and
under enforcing AOSP refuses that outright, so the helper simply does not run.

The dumpstate helpers are the bulk of it -- hal_dumpstate_default forks them, not init.

Run from the tree root.
"""

import os
import re
import sys

STOCK = os.path.expanduser(
    "~/Projects/yogi/crdroid/b1-dump/dump/vendor/etc/selinux/vendor_sepolicy.cil")
DOMAINS = "device/google/yogi/sepolicy/vendor/device_domains.te"
TT = re.compile(r"^\(typetransition\s+(\S+)\s+(\S+)\s+process\s+(\S+)\)", re.M)
VER = re.compile(r"_\d{6}$")


def main():
    stock = {}
    for src, exe, dst in TT.findall(open(STOCK).read()):
        stock[VER.sub("", dst)] = (VER.sub("", src), VER.sub("", exe))

    body = open(DOMAINS, encoding="utf-8").read()
    fixed, kept = [], 0
    out = []
    for line in body.splitlines(True):
        m = re.match(r"^init_daemon_domain\(([A-Za-z0-9_-]+)\)\s*$", line)
        if not m:
            out.append(line)
            continue
        dom = m.group(1)
        src, exe = stock.get(dom, ("init", dom + "_exec"))
        if src == "init":
            out.append(line)
            kept += 1
            continue
        out.append("domain_auto_trans(%s, %s, %s)\n" % (src, exe, dom))
        fixed.append((dom, src))

    if fixed:
        hdr = ("# Domains whose parent is not init use domain_auto_trans with the parent stock\n"
               "# gives them. init_daemon_domain here would mean no transition ever happens.\n")
        text = "".join(out)
        if hdr not in text:
            text = text.replace("domain_auto_trans(", hdr + "domain_auto_trans(", 1)
        open(DOMAINS, "w", encoding="utf-8").write(text)

    print("init_daemon_domain kept: %d ; corrected to domain_auto_trans: %d"
          % (kept, len(fixed)))
    for dom, src in sorted(fixed):
        print("   %-34s <- %s" % (dom, src))


if __name__ == "__main__":
    main()
