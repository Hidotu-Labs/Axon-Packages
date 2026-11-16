#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/rsync-3.5.0.tar.gz"
source_url="https://download.samba.org/pub/rsync/src/rsync-3.5.0.tar.gz"
source_sha256="c7ffd1ef653e99540f661e47cb00b7f9cad1ee6b972399b16f93d672656e0d33"
source_dir="$work_dir/rsync-3.5.0"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/rsync-3.5.0-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure --prefix=/usr --with-rrsync CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"
install -Dm644 "$source_dir/packaging/systemd/rsync@.service" \
    "$stage_dir/usr/lib/systemd/system/rsyncd@.service"
install -Dm644 "$source_dir/packaging/systemd/rsync.service" \
    "$stage_dir/usr/lib/systemd/system/rsyncd.service"
sed 's/Conflicts=rsync.service/Conflicts=rsyncd.service/' \
    "$source_dir/packaging/systemd/rsync.socket" \
    > "$work_dir/rsyncd.socket"
install -Dm644 "$work_dir/rsyncd.socket" \
    "$stage_dir/usr/lib/systemd/system/rsyncd.socket"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
