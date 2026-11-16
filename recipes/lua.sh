#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/lua-5.4.7.tar.gz"
source_url="https://www.lua.org/ftp/lua-5.4.7.tar.gz"
source_sha256="9fbf5e28ef86c69858f6d3d34eccc32e911c1a28b4120ff3e84aaa70cfbf1e30"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/lua-5.4.7-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

make -C "$work_dir/lua-5.4.7" linux MYCFLAGS="$CFLAGS"
make -C "$work_dir/lua-5.4.7" install INSTALL_TOP="$stage_dir/usr"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
