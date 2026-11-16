#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/cjson-1.7.19.tar.gz"
source_url="https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.19.tar.gz"
source_sha256="7fa616e3046edfa7a28a32d5f9eacfd23f92900fe1f8ccd988c1662f30454562"
source_dir="$work_dir/cJSON-1.7.19"
build_dir="$work_dir/build"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/cjson-1.7.19-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cmake -S "$source_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_SHARED_AND_STATIC_LIBS=ON \
    -DENABLE_CJSON_TEST=Off \
    -DENABLE_CJSON_UTILS=Off
cmake --build "$build_dir" --parallel
DESTDIR="$stage_dir" cmake --install "$build_dir"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
