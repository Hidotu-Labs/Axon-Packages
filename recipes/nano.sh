#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/nano-9.2.tar.xz"
source_url="https://www.nano-editor.org/dist/v9/nano-9.2.tar.xz"
source_sha256="05ecb99247b782e8a5b3a25ed4101dd034b0236902f7449bc9795b717642f7e9"
source_dir="$work_dir/nano-9.2"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/nano-9.2-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xJf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --enable-utf8 \
    --enable-color \
    --enable-nanorc \
    --enable-nls \
    CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
