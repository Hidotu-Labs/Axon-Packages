#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/htop-3.5.3.tar.gz"
source_url="https://github.com/htop-dev/htop/archive/refs/tags/3.5.3.tar.gz"
source_sha256="edf25ee020a5263ffbef9eef5a8c14392bf74e78b3d5c8bc64d9343dd9a82605"
source_dir="$work_dir/htop-3.5.3"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/htop-3.5.3-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./autogen.sh
./configure --prefix=/usr --enable-unicode CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"
install -Dm644 "$source_dir/htop.png" "$stage_dir/usr/share/pixmaps/htop.png"
install -Dm644 "$source_dir/htop.svg" \
    "$stage_dir/usr/share/icons/hicolor/scalable/apps/htop.svg"
install -Dm644 "$source_dir/htop.desktop" \
    "$stage_dir/usr/share/applications/htop.desktop"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
