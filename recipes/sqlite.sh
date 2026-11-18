#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/axon-sqlite.XXXXXX")
source_archive="$work_dir/sqlite-src-3530400.zip"
source_url="https://www.sqlite.org/2026/sqlite-src-3530400.zip"
source_sha256="d18fa15aec74d8c17e1463f861095adc01b5ad190256acb4f91d22f0368d232b"
source_dir="$work_dir/sqlite-src-3530400"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/sqlite-3.53.4-x86_64.tar.gz"
compiler=${CC:-gcc}

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
unzip -q "$source_archive" -d "$work_dir"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --all \
    --session \
    CFLAGS="$CFLAGS -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_STAT4"
make -j2
make install DESTDIR="$stage_dir"
install -Dm644 "$source_dir/LICENSE.md" \
    "$stage_dir/usr/share/licenses/sqlite/license.txt"
gzip -n -9 "$stage_dir/usr/share/man/man1/sqlite3.1"

helper_cflags="$CFLAGS -I$source_dir -I$source_dir/src -I$source_dir/ext/misc -I$source_dir/ext/expert"
helper_libs="-L$stage_dir/usr/lib -lsqlite3"
$compiler $helper_cflags -DDBDUMP_STANDALONE "$source_dir/ext/misc/dbdump.c" $helper_libs -o "$stage_dir/usr/bin/dbdump"
$compiler $helper_cflags "$source_dir/tool/dbhash.c" $helper_libs -o "$stage_dir/usr/bin/dbhash"
$compiler $helper_cflags "$source_dir/tool/dbtotxt.c" -o "$stage_dir/usr/bin/dbtotxt"
$compiler $helper_cflags "$source_dir/tool/index_usage.c" $helper_libs -o "$stage_dir/usr/bin/index_usage"
$compiler $helper_cflags "$source_dir/tool/showdb.c" $helper_libs -o "$stage_dir/usr/bin/showdb"
$compiler $helper_cflags "$source_dir/tool/showjournal.c" -o "$stage_dir/usr/bin/showjournal"
$compiler $helper_cflags "$source_dir/tool/showshm.c" -o "$stage_dir/usr/bin/showshm"
$compiler $helper_cflags "$source_dir/tool/showstat4.c" $helper_libs -o "$stage_dir/usr/bin/showstat4"
$compiler $helper_cflags "$source_dir/tool/showwal.c" -o "$stage_dir/usr/bin/showwal"
$compiler $helper_cflags "$source_dir/tool/sqldiff.c" "$source_dir/ext/misc/sqlite3_stdio.c" $helper_libs -o "$stage_dir/usr/bin/sqldiff"
$compiler $helper_cflags -pthread "$source_dir/tool/sqlite3_rsync.c" $helper_libs -o "$stage_dir/usr/bin/sqlite3_rsync"
$compiler $helper_cflags "$source_dir/ext/expert/expert.c" "$source_dir/ext/expert/sqlite3expert.c" $helper_libs -o "$stage_dir/usr/bin/sqlite3_expert"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
