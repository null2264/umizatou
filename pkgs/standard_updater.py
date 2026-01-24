#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3.pkgs.requests python3.pkgs.lxml nix

import json
import os
import requests
import subprocess
import sys

"""
For kexts released by acidanthera or kexts that used acidanthera's standard release format.
"""

if len(sys.argv) < 4:
    print("Usage: standard_updater.py <org> <repo> <filename>")
    sys.exit(1)

def nix_prefetch_sha256(url):
    return subprocess.run(["nix-prefetch-url", "--type", "sha256", "--unpack", url], capture_output=True, text=True).stdout.strip()

session = requests.session()
org = sys.argv[1]
repo = sys.argv[2]
filename = sys.argv[3]
data = session.get(f"https://api.github.com/repos/{org}/{repo}/releases").json()

def normalise_version(ver):
    return ver.replace(".", "_").lstrip("v")

catalogue = {}
for index, i in enumerate(data):
    for r in ["RELEASE", "DEBUG"]:
        name = repo.lower()
        if r == "DEBUG":
            name += "-debug"
        version = i.get("tag_name")
        url = f"https://github.com/{org}/{repo}/releases/download/{version}/{filename}-{version.lstrip("v")}-{r}.zip"
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

d = os.getcwd()
with open(os.path.join(d, 'versions.json'), 'w') as f:
    json.dump(catalogue, f, indent=4)
    f.write('\n')
