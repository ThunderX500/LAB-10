#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Reuse the exact Lab 7 revision, not a moving branch.
git clone https://github.com/ThunderX500/LAB7.git "$tmp/lab7"
git -C "$tmp/lab7" checkout --detach 37df8c5711d40a1b97990959edb4af1f671e8ffb

# Only import files that do not already exist, preserving Lab 10 changes.
mkdir -p "$root/books-rest-api" "$root/bookstore-client"
cp -Rn "$tmp/lab7/server/." "$root/books-rest-api/"
cp -Rn "$tmp/lab7/client/." "$root/bookstore-client/"

test -f "$root/books-rest-api/gradle/wrapper/gradle-wrapper.jar"
test -f "$root/bookstore-client/package.json"
printf '%s\n' "Lab 7 application files imported. Docker configurations preserved."
