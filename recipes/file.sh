#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/file-5.48.tar.gz"
source_url="https://astron.com/pub/file/file-5.48.tar.gz"
source_sha256="ed14656883b23a364b4057c05595d93252da9bc473d30106519519d0da141283"
source_dir="$work_dir/file-5.48"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/file-5.48-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure \
    --prefix=/usr \
    --datadir=/usr/share/file \
    --libdir=/usr/lib \
    --disable-static \
    --enable-shared \
    CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"
install -Dm644 "$source_dir/COPYING" "$stage_dir/usr/share/licenses/file/COPYING"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
