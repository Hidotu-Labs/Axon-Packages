#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/jq-1.8.2.tar.gz"
source_url="https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-1.8.2.tar.gz"
source_sha256="71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af"
source_dir="$work_dir/jq-1.8.2"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/jq-1.8.2-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --enable-shared \
    --disable-static \
    CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"
install -Dm644 README.md "$stage_dir/usr/share/doc/jq/README.md"
install -Dm644 NEWS.md "$stage_dir/usr/share/doc/jq/NEWS.md"
install -Dm644 COPYING "$stage_dir/usr/share/licenses/jq/COPYING"
install -Dm644 COPYING "$stage_dir/usr/share/doc/jq/COPYING"
install -Dm644 AUTHORS "$stage_dir/usr/share/doc/jq/AUTHORS"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
