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
    parts = version_str.split('.')
    processed_parts = [parts[0]] + [part.zfill(3) for part in parts[1:]]
    result = "".join(processed_parts)
    return int(result)

def normalise_version(ver):
    return ver.replace(".", "_").lstrip("v")

def get_quirk(version, release_type):
    if pname == "yogasmc":
        url = construct_url(version, version != "1.1.0", release_type)
        if release_type == "RELEASE" and version == "1.5.0":
            url = None
        return {
            "type": "yogasmc",
            "url": url,
        }
    return None

def construct_url(version, omit_version, release_type):
    file_format = f"{filename}-{version.lstrip("v")}-{release_type}.zip" if not omit_version else f"{filename}-{release_type}.zip"
    return f"https://github.com/{org}/{repo}/releases/download/{version}/{file_format}"

d = os.path.dirname(os.path.abspath(__file__))
target = f"kexts/{os.environ.get('UPDATE_NIX_PNAME') or repo.lower()}"
if org == "acidanthera" and repo.lower() == "opencorepkg":
    target = "opencore"
    pname = "opencore"
target += "/versions.json"
try:
    with open(os.path.join(d, target), "r") as f:
        prev = json.load(f)
except FileNotFoundError:
    prev = {}

changed = 0
catalogue = {}
for index, i in enumerate(data):
    for r in ["RELEASE", "DEBUG"]:
        _name = pname
        if r == "DEBUG":
            _name += "-debug"
        version = i.get("tag_name")
        url = construct_url(version, args.omit_version, r)

        quirk = get_quirk(version, r)
        if quirk:
            if quirk["type"] == "yogasmc":
                url = quirk["url"]

        if not url:
            continue

        key = f"{_name}{'-debug' if r == 'DEBUG' else ''}_{normalise_version(version)}"

        prev_data = prev.get(key)
        if prev_data is not None and prev_data.get("sha256") is not None and not args.force_reindex:
            catalogue[key] = prev_data

            if (index) == 0:
                # Alias for latest
                catalogue[_name] = prev_data
            continue

        changed += 1

        current_data = {
            "version": version.lstrip("v"),
            "sha256": nix_prefetch_sha256(url),
            "url": url,
        }
        catalogue[key] = current_data

        if (index) == 0:
            # Alias for latest
            catalogue[_name] = current_data

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
