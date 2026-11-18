#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/coreutils-9.12.tar.xz"
source_url="https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz"
source_sha256="a480198559733e9b3da999e90543ac6f888a2caa544d8d664c5a1f17e528e210"
source_dir="$work_dir/coreutils-9.12"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/coreutils-9.12-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xJf "$source_archive" -C "$work_dir"
patch -d "$source_dir" -p1 < "$recipe_dir/coreutils-uname.patch"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure \
    --prefix=/usr \
    --libdir=/usr/lib \
    --libexecdir=/usr/lib/coreutils \
    --enable-nls \
    --without-selinux \
    CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"

cat > "$work_dir/uname-override.c" <<'EOF'
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>

int uname(struct utsname *name) {
    memset(name, 0, sizeof *name);
    strcpy(name->sysname, getenv("AXON_TEST_SYSNAME"));
    return 0;
}
EOF
${CC:-gcc} -shared -fPIC "$work_dir/uname-override.c" -o "$work_dir/uname-override.so"
ascension_output=$(AXON_TEST_SYSNAME=Ascension LD_PRELOAD="$work_dir/uname-override.so" "$stage_dir/usr/bin/uname" -o)
linux_output=$(AXON_TEST_SYSNAME=Linux LD_PRELOAD="$work_dir/uname-override.so" "$stage_dir/usr/bin/uname" -o)
test "$ascension_output" = Ascension
test "$linux_output" = GNU/Linux

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
