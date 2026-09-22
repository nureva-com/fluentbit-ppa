#!/bin/bash
set -e

cd "$(dirname "$0")/.."

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo "Usage: $0 <gpg-key-selector>" >&2
    exit 1
fi

# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages

# Release, Release.gpg, InRelease & KEY.gpg
apt-ftparchive release . > Release
gpg --armor --export "$1" > KEY.gpg
gpg --default-key "$1" -abs -o - Release > Release.gpg
gpg --default-key "$1" --clearsign -o - Release > InRelease