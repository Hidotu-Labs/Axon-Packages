#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/zstd-1.5.7.tar.gz"
source_url="https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz"
source_sha256="eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3"
source_dir="$work_dir/zstd-1.5.7"
build_dir="$work_dir/build"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/zstd-1.5.7-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cmake -S "$source_dir/build/cmake" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DZSTD_BUILD_PROGRAMS=ON
cmake --build "$build_dir" --parallel
DESTDIR="$stage_dir" cmake --install "$build_dir"
install -Dm644 "$source_dir/LICENSE" "$stage_dir/usr/share/licenses/zstd/LICENSE"
install -Dm644 "$source_dir/doc/zstd_manual.html" "$stage_dir/usr/share/doc/zstd/zstd_manual.html"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
