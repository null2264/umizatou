#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3.pkgs.requests python3.pkgs.lxml nix

import argparse
import json
import os
import re
import requests
import subprocess
import sys

# 1. Create the parser
parser = argparse.ArgumentParser(description="Updater for kexts released by acidanthera or kexts that used acidanthera's standard release format.")

parser.add_argument("org", type=str, help="the repository's owner")
parser.add_argument("repo", type=str, help="the repository's name")
parser.add_argument("--filename", type=str, help="the releases' filename")
parser.add_argument("--pname", type=str, help="the package's name")
parser.add_argument("--omit-version", action="store_true", help="omit version from release filename (e.g. YogaSMC-Release.zip instead of YogaSMC-1.0.0-Release.zip)")
parser.add_argument("--force-reindex", action="store_true", help="force existing version to refresh its data")
parser.add_argument("--verbose", "-v", action="store_true", help="print log")
args = parser.parse_args()

def nix_prefetch_sha256(url):
    if args.verbose:
        print(f"Fetching {url}...")
    return subprocess.run(["nix-prefetch-url", "--type", "sha256", "--unpack", url], capture_output=True, text=True).stdout.strip()

session = requests.session()
org = args.org
repo = args.repo
filename = args.filename or repo
data = session.get(f"https://api.github.com/repos/{org}/{repo}/releases").json()
pname = os.environ.get('UPDATE_NIX_PNAME') or args.pname or repo.lower()

def version_number(version_str):
    parts = version_str.lstrip("v").split('.')
    if len(parts) < 3:
        parts.append("0")
    processed_parts = [parts[0]] + [part.zfill(3) for part in parts[1:]]
    result = "".join(processed_parts)
    return int(result)

def normalise_version(ver):
    return ver.replace(".", "_").lstrip("v")

def get_quirk(version, release_type):
    if pname == "yogasmc":
        url = construct_url(version, release_type, omit_version = version != "1.1.0")
        if release_type == "RELEASE" and version == "1.5.0":
            url = None
        return {
            "type": "url",
            "url": url,
        }
    elif pname == "cpufriend":
        ver = version_number(version)
        url = construct_url(version, release_type, omit_filename = ver < 1_001_009)
        if ver < 1_001_009:
            url = url.replace("-", ".")
        return {
            "type": "url",
            "url": url,
        }
    elif pname == "hibernationfixup":
        ver = version_number(version)
        url = construct_url(version, release_type, omit_filename = ver < 1_002_007)
        if ver < 1_002_007:
            url = url.replace("-", ".")
        return {
            "type": "url",
            "url": url,
        }
    elif pname == "intel-bluetooth-firmware":
        if release_type == "DEBUG":
            # They didn't release DEBUG file
            return { "type": "skip" }

        # Their releases is so inconsistent but since they only ever release
        # one file per version we could just yoink it from github API directly
        return {
            "type": "assets",
            "url": None,
        }
    elif pname == "intel-mausi":
        ver = version_number(version)
        url = construct_url(version, release_type, omit_filename = ver < 1_000_001)
        if ver < 1_000_001:
            url = url.replace("-", ".")
        return {
            "type": "url",
            "url": url,
        }
    elif pname == "itlwm":
        if release_type == "DEBUG":
            # They didn't release DEBUG file
            return { "type": "skip" }

        return {
            "type": "url",
            "url": construct_url(version, release_type, file_format = f"{pname}_{version}_stable.kext.zip"),
        }
    elif pname == "rtcmemoryfixup":
        ver = version_number(version)
        url = construct_url(version, release_type, omit_filename = ver < 1_000_004)
        if ver < 1_000_004:
            url = url.replace("-", ".")
        return {
            "type": "url",
            "url": url,
        }
    elif pname == "usbtoolbox":
        url = construct_url(version, release_type)
        if version == "1.1.0":
            # I don't even know man...
            url = construct_url(version, release_type, file_format = f"USBToolBox-1.0.1-{release_type}.zip")
        return {
            "type": "url",
            "url": url,
        }
    elif pname == "voltageshift":
        if release_type == "DEBUG":
            # They didn't release DEBUG file
            return { "type": "skip" }

        return {
            "type": "url",
            "url": construct_url(version, release_type, file_format = f"VoltageShift{version}.zip"),
        }
    elif pname == "voodooi2c":
        ver = version_number(version)
        if ver < 2_009_001 and release_type == "DEBUG" or ver == 2_009_000:
            # They didn't release DEBUG file
            return { "type": "skip" }

        url = construct_url(version, release_type)
        if ver < 2_009_001 and not ver == 2_001_001:
            url = construct_url(version, release_type, file_format = f"VoodooI2C-{version}.zip")
        elif ver == 2_001_001:
            url = construct_url(version, release_type, file_format = f"VoodooI2C.{version}.zip")

        return {
            "type": "url",
            "url": url,
        }
    elif pname == "voodoormi":
        url = construct_url(version, release_type)
        if version == "1.2":
            url = url.replace(f"-{version}", f".{version}")
        return {
            "type": "url",
            "url": url,
        }

    return None

def construct_url(version, release_type, *, omit_version = False, omit_filename = False, strip_v = True, file_format = ""):
    assert not (omit_version and omit_filename), "omit_version and omit_filename can't be both True"
    if not file_format:
        file_format = f"{release_type}.zip"
        _version = version
        if strip_v:
            _version = version.lstrip("v").lstrip(".")

        if omit_version:
            file_format = f"{filename}-{file_format}"
        elif omit_filename:
            file_format = f"{_version}-{file_format}"
        else:
            file_format = f"{filename}-{_version}-{file_format}"
    return f"https://github.com/{org}/{repo}/releases/download/{version}/{file_format}"

d = os.path.dirname(os.path.abspath(__file__))
target = f"kexts/{pname}"
if org == "acidanthera" and repo.lower() == "opencorepkg":
    target = "opencore"
    pname = "opencore"
target += "/versions.json"
try:
    with open(os.path.join(d, target), "r") as f:
        prev = json.load(f)
except FileNotFoundError:
    prev = {}

failed = []
changed = 0
catalogue = {}
for index, i in enumerate(data):
    for r in ["RELEASE", "DEBUG"]:
        _name = pname
        if r == "DEBUG":
            _name += "-debug"
        version = i.get("tag_name")
        url = construct_url(version, r, omit_version = args.omit_version)

        quirk = get_quirk(version, r)
        if quirk:
            if quirk["type"] == "url":
                url = quirk["url"]
            elif quirk["type"] == "assets":
                url = i["assets"][0]["browser_download_url"]
            elif quirk["type"] == "skip":
                continue

        if not url:
            continue

        key = f"{_name}_{normalise_version(version).lower()}"

        prev_data = prev.get(key)
        if prev_data is not None and prev_data.get("sha256", "") != "" and not args.force_reindex:
            catalogue[key] = prev_data

            if (index) == 0:
                # Alias for latest
                catalogue[_name] = prev_data
            continue

        changed += 1

        sha256 = nix_prefetch_sha256(url)
        if not sha256:
            if index == 0:
                raise RuntimeError(f"Failed to fetch hash for latest version ({version})")
            failed.append(key)
        current_data = {
            "version": version.lstrip("v"),
            "sha256": sha256,
            "url": url,
        }
        catalogue[key] = current_data

        if (index) == 0:
            # Alias for latest
            catalogue[_name] = current_data

if failed:
    _target = f"kexts/{pname}"
    if org == "acidanthera" and repo.lower() == "opencorepkg":
        _target = "opencore"
    _target += "/failed.json"
    with open(os.path.join(d, _target), "w") as f:
        json.dump(failed, f, indent=4)
        f.write('\n')

if changed > 0:
    changes = [ { "commitMessage": f"{pname}Packages: update versions\n\n" } ]

    for key, value in sorted({**prev, **catalogue}.items(), key=lambda item: [int(s) if s.isdigit() else s for s in re.split(r'(\d+)', item[0])]):
        if key not in prev:
            changes[0]["commitMessage"] += f"{pname}Packages.{key}: init at {value['version']}\n"
        elif value['version'] != prev[key]['version']:
            changes[0]["commitMessage"] += f"{pname}Packages.{key}: {prev[key]['version']} -> {value['version']}\n"

    print(json.dumps(changes))

    with open(os.path.join(d, target), "w") as f:
        json.dump(catalogue, f, indent=4)
        f.write('\n')
