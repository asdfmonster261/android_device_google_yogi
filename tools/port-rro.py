#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Turn a stock auto_generated_rro apk into an RRO resource tree.
#
#   port-rro.py <stock.apk> <out-res-dir> --aosp-res <dir> [--aosp-res <dir> ...]
#
# Only names the target package declares are kept, and each one is emitted with the
# element form the target declares it with. A name the target does not declare would
# simply never idmap, and a mismatched form changes the type.

import argparse
import os
import re
import subprocess
import sys
from collections import defaultdict

AAPT2 = os.environ.get("AAPT2", "out/host/linux-x86/bin/aapt2")

# Build-generated pseudo-locales; never real translations.
PSEUDO = ("en-rXA", "ar-rXB", "en-rXC")

# Values naming a class the framework loads by reflection. Stock points these at Google
# framework classes this build does not carry, and the loader throws rather than falling
# back, so shipping the override kills system_server at boot. A package or component name
# is fine here, because a lookup that finds nothing just leaves the feature inert; it is
# specifically Class.forName that cannot survive the move.
DROP = (
    # DeviceStatePolicy.Provider.fromResources: empty gives DefaultProvider, a name it
    # cannot load throws IllegalStateException. The default reads the same fold config.
    "config_deviceSpecificDeviceStatePolicyProvider",
)

RES_TYPES = ("bool", "integer", "string", "dimen", "color", "array",
             "string-array", "integer-array", "fraction")


def aosp_declarations(dirs):
    """name -> (element, attrs) as the target declares it."""
    # The whole opening tag, because AOSP writes type= on either side of name= and
    # reading only what precedes name= silently loses it.
    tag = re.compile(r'<(\w[\w-]*)((?:\s+[\w:.-]+\s*=\s*"[^"]*")+)\s*/?>', re.S)
    namere = re.compile(r'\bname\s*=\s*"([^"]+)"')
    skip = ("resources", "public", "java-symbol", "attr", "eat-comment")
    out = {}
    for d in dirs:
        for root, _, files in os.walk(d):
            for f in files:
                if not f.endswith(".xml"):
                    continue
                try:
                    txt = open(os.path.join(root, f), encoding="utf-8",
                               errors="replace").read()
                except OSError:
                    continue
                for m in tag.finditer(txt):
                    el, attrs = m.group(1), m.group(2)
                    if el in skip:
                        continue
                    nm = namere.search(attrs)
                    if nm:
                        out.setdefault(nm.group(1), (el, attrs.strip()))
    return out


def split_items(s):
    """Split an aapt2 array body on commas that are not inside quotes."""
    items, buf, q, esc = [], "", False, False
    for ch in s:
        if esc:
            buf += ch
            esc = False
            continue
        if ch == chr(92):
            buf += ch
            esc = True
            continue
        if ch == chr(34):
            q = not q
            buf += ch
            continue
        if ch == "," and not q:
            items.append(buf.strip())
            buf = ""
            continue
        buf += ch
    if buf.strip():
        items.append(buf.strip())
    return items


def parse(apk):
    """-> {(config, rtype, name): value}, skipped_file_count"""
    out = subprocess.run([AAPT2, "dump", "resources", apk],
                         capture_output=True, text=True).stdout.split("\n")
    res, skipped = {}, 0
    rtype = name = None
    i = 0
    while i < len(out):
        ln = out[i]
        m = re.match(r"^  type ([\w-]+) id=", ln)
        if m:
            rtype = m.group(1)
            i += 1
            continue
        m = re.match(r"^    resource 0x\w+ [\w-]+/(\S+)", ln)
        if m:
            name = m.group(1)
            i += 1
            continue
        m = re.match(r"^      \(([^)]*)\) (.*)$", ln)
        if m and name:
            cfg, val = m.group(1), m.group(2).strip()
            if "(file)" in val:
                skipped += 1
                i += 1
                continue
            am = re.match(r"^\(array\) size=(\d+)$", val)
            if am:
                want = int(am.group(1))
                body, i = "", i + 1
                while i < len(out) and not re.match(r"^      \(|^    resource |^  type ", out[i]):
                    body += " " + out[i].strip()
                    i += 1
                body = body.strip()
                if body.startswith("[") and body.endswith("]"):
                    body = body[1:-1]
                items = split_items(body)
                if len(items) != want:
                    print("  WARN %s: array %s parsed %d items, aapt2 said %d"
                          % (os.path.basename(apk), name, len(items), want), file=sys.stderr)
                res[(cfg, rtype, name)] = items
                continue
            res[(cfg, rtype, name)] = val
            i += 1
            continue
        i += 1
    return res, skipped


def esc(v):
    if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
        v = v[1:-1]
    # A resource reference is not text and must not be escaped at all.
    if re.match(r"^@\+?(\w+:)?[a-z]+/\w+$", v):
        return v
    # Backslash first, or the escapes below get doubled.
    v = v.replace('\\', '\\\\')
    v = v.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    # aapt2 rejects a bare apostrophe or quote in a string resource.
    v = v.replace("'", "\\'")
    v = v.replace('"', '\\"')
    # A leading @ or ? that is not a reference would be read as one.
    if v[:1] in ("@", "?"):
        v = '\\' + v
    return v


def cfgdir(cfg):
    if not cfg:
        return "values"
    # aapt2 re-derives the -vNN api qualifier, so AOSP source dirs omit it.
    cfg = re.sub(r"-v\d+$", "", cfg)
    return "values-" + cfg if cfg else "values"


REF = re.compile(r"@(\+)?(?:(\w+):)?[a-z-]+/(\w+)")


def refs_of(v):
    """Names this value references, excluding explicitly-packaged ones."""
    out = []
    for item in (v if isinstance(v, list) else [v]):
        for m in REF.finditer(item):
            if m.group(2):          # @android:string/ok resolves elsewhere
                continue
            out.append(m.group(3))
    return out


def select(vals, decls):
    """Names to keep: overrides of the target, plus the overlay own helpers they
    reference. Stock declares those helpers inside the overlay apk, so a value
    that points at one is only valid if the helper comes along."""
    present = set(n for (_, _, n) in vals)
    keep = set(n for (_, _, n) in vals if n in decls and n not in DROP)
    while True:
        add = set()
        for (_, _, n), v in vals.items():
            if n not in keep:
                continue
            for r in refs_of(v):
                if r not in keep and r in present:
                    add.add(r)
        if not add:
            break
        keep |= add
    # Anything still pointing outside both sets cannot link.
    broken = set()
    for (_, _, n), v in vals.items():
        if n not in keep:
            continue
        for r in refs_of(v):
            if r not in keep and r not in decls:
                broken.add(n)
    return keep - broken, broken


def emit(vals, decls, outdir):
    by_dir = defaultdict(list)
    keep, broken = select(vals, decls)
    kept = dropped = unresolved = 0
    for (cfg, rtype, name), v in sorted(vals.items(), key=lambda k: (k[0][0], k[0][2])):
        if any(cfg == x or cfg.startswith(x + "-") for x in PSEUDO):
            continue
        if name not in keep:
            dropped += 1
            continue
        if not isinstance(v, list) and re.match(r"^[@?]0x[0-9a-fA-F]+$", v.strip(chr(34))):
            unresolved += 1
            continue
        kept += 1
        # For an overlay-local helper the target does not declare, use the type aapt2
        # reported. Guessing from the python type emits <string>true</string>, and a
        # reference to @bool/x then cannot resolve against a string of the same name.
        fallback = "array" if isinstance(v, list) else rtype
        el, attrs = decls.get(name, (fallback, ""))
        if isinstance(v, list):
            body = "".join("        <item>%s</item>\n" % esc(x) for x in v)
            by_dir[cfgdir(cfg)].append(
                "    <%s name=\"%s\">\n%s    </%s>" % (el, name, body, el))
        else:
            extra = ""
            tm = re.search(r"type\s*=\s*\"(\w+)\"", attrs)
            if tm:
                extra += " type=\"%s\"" % tm.group(1)
            fm = re.search(r"format\s*=\s*\"(\w+)\"", attrs)
            if fm:
                extra += " format=\"%s\"" % fm.group(1)
            by_dir[cfgdir(cfg)].append(
                "    <%s name=\"%s\"%s>%s</%s>" % (el, name, extra, esc(v), el))
    if broken:
        print("  dropped %d resource(s) referencing something that cannot resolve: %s"
              % (len(broken), ", ".join(sorted(broken)[:6])))
    for d, lines in by_dir.items():
        os.makedirs(os.path.join(outdir, d), exist_ok=True)
        with open(os.path.join(outdir, d, "config.xml"), "w", encoding="utf-8") as f:
            f.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n")
            f.write("\n".join(lines))
            f.write("\n</resources>\n")
        print("  %-34s %d" % (d + "/config.xml", len(lines)))
    return kept, dropped, unresolved


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("apk")
    ap.add_argument("outdir")
    ap.add_argument("--aosp-res", action="append", required=True)
    a = ap.parse_args()

    decls = aosp_declarations(a.aosp_res)
    print("target declares %d resource names" % len(decls))
    vals, skipped = parse(a.apk)
    print("overlay carries %d (config,name) values, %d file resources skipped"
          % (len(vals), skipped))
    kept, dropped, unresolved = emit(vals, decls, a.outdir)
    print("kept %d, dropped %d not declared by the target, %d unresolved refs"
          % (kept, dropped, unresolved))


main()
