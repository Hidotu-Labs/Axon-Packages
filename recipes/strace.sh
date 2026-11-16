#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/strace-7.2.tar.xz"
source_url="https://strace.io/files/7.2/strace-7.2.tar.xz"
source_sha256="4bde6246926890dcee824f6e6ac42a06752f47d77e5097d86e3c0d6d4b709fe5"
source_dir="$work_dir/strace-7.2"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/strace-7.2-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xJf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure --prefix=/usr --enable-mpers=no CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
