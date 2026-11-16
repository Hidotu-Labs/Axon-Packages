#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/tree-2.3.2.tar.gz"
source_url="https://github.com/Old-Man-Programmer/tree/archive/refs/tags/2.3.2.tar.gz"
source_sha256="22cf32e84e3eb508d97a9e991c2c3cc006b9dcf4afed201d96311c5c57d08fcf"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/tree-2.3.2-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

make -C "$work_dir/tree-2.3.2" \
    CC="${CC:-gcc}" \
    CFLAGS="$CFLAGS" \
    PREFIX=/usr \
    DESTDIR="$stage_dir/usr/bin" \
    MANDIR="$stage_dir/usr/share/man" \
    install

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
