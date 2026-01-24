#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3.pkgs.requests python3.pkgs.lxml nix

import argparse
import json
import os
import requests
import subprocess
import sys

# 1. Create the parser
parser = argparse.ArgumentParser(description="Updater for kexts released by acidanthera or kexts that used acidanthera's standard release format.")

parser.add_argument("org", type=str, help="the repository's owner")
parser.add_argument("repo", type=str, help="the repository's name")
parser.add_argument("--filename", type=str, help="the releases' filename")
parser.add_argument("--omit-version", action="store_true", help="omit version from release filename (e.g. YogaSMC-Release.zip instead of YogaSMC-1.0.0-Release.zip)")
args = parser.parse_args()

def nix_prefetch_sha256(url):
    return subprocess.run(["nix-prefetch-url", "--type", "sha256", "--unpack", url], capture_output=True, text=True).stdout.strip()

session = requests.session()
org = sys.argv[1]
repo = sys.argv[2]
filename = repo if len(sys.argv) < 4 else sys.argv[3]
data = session.get(f"https://api.github.com/repos/{org}/{repo}/releases").json()
pname = os.environ.get('UPDATE_NIX_PNAME') or repo.lower()

def version_number(version_str):
    parts = version_str.split('.')
    processed_parts = [parts[0]] + [part.zfill(3) for part in parts[1:]]
    result = "".join(processed_parts)
    return int(result)

def normalise_version(ver):
    return ver.replace(".", "_").lstrip("v")

def get_quirk(version, release_type):
    if pname == "yogasmc":
        return {
            "type": "yogasmc",
            "url": construct_url(version, version != "1.1.0", release_type),
        }
    return None

def construct_url(version, omit_version, release_type):
    file_format = f"{filename}-{version.lstrip("v")}-{release_type}.zip" if omit_version else f"{filename}-{release_type}.zip"
    return f"https://github.com/{org}/{repo}/releases/download/{version}/{file_format}"

catalogue = {}
for index, i in enumerate(data):
    for r in ["RELEASE", "DEBUG"]:
        name = repo.lower()
        if r == "DEBUG":
            name += "-debug"
        version = i.get("tag_name")
        url = construct_url(version, args, omit_version, release_type)

        quirk = get_quirk(version, release_type)
        if quirk:
            if quirk["type"] == "yogasmc":
                url = quirk["url"]

        current_data = {
            "version": version.lstrip("v"),
            "sha256": nix_prefetch_sha256(url),
            "url": url,
        }
        catalogue[f"{name}_{normalise_version(version)}"] = current_data

        if (index) == 0:
            # Alias for latest
            catalogue[name] = current_data

changes = [ { "commitMessage": f"{repo.lower()}Packages: update versions\n\n" } ]

print(json.dumps(changes))

d = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(d, f"kexts/{os.environ.get('UPDATE_NIX_PNAME') or repo.lower()}/versions.json"), "w") as f:
    json.dump(catalogue, f, indent=4)
    f.write('\n')
