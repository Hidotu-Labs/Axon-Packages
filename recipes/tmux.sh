#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
libevent_archive="$work_dir/libevent-2.1.12-stable.tar.gz"
libevent_url="https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz"
libevent_sha256="92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb"
tmux_archive="$work_dir/tmux-3.8.tar.gz"
tmux_url="https://github.com/tmux/tmux/releases/download/3.8/tmux-3.8.tar.gz"
tmux_sha256="e79c699c7e949dccd0a4a125e17b8d1261e311b16979dbc8eb34542f3966d82e"
dep_prefix="$work_dir/deps"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/tmux-3.8-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$libevent_archive" "$libevent_url"
printf '%s  %s\n' "$libevent_sha256" "$libevent_archive" | sha256sum -c -
tar -xzf "$libevent_archive" -C "$work_dir"
curl -fL --retry 2 -o "$tmux_archive" "$tmux_url"
printf '%s  %s\n' "$tmux_sha256" "$tmux_archive" | sha256sum -c -
tar -xzf "$tmux_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$work_dir/libevent-2.1.12-stable"
./configure --prefix="$dep_prefix" --disable-shared --enable-static
make -j2
make install

cd "$work_dir/tmux-3.8"
PKG_CONFIG_PATH="$dep_prefix/lib/pkgconfig" \
CPPFLAGS="-I$dep_prefix/include" \
LDFLAGS="-L$dep_prefix/lib" \
./configure --prefix=/usr CFLAGS="$CFLAGS"
PKG_CONFIG_PATH="$dep_prefix/lib/pkgconfig" \
CPPFLAGS="-I$dep_prefix/include" \
LDFLAGS="-L$dep_prefix/lib" \
make -j2
make install DESTDIR="$stage_dir"
install -Dm644 "$work_dir/tmux-3.8/COPYING" \
    "$stage_dir/usr/share/licenses/tmux/LICENSE"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
