#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_dir="$work_dir/tinycc"
source_commit="086870addd9599ef74bed8e81ebb353da7836709"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/tcc-0.9.28rc-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

git clone -q https://repo.or.cz/tinycc.git "$source_dir"
git -C "$source_dir" checkout -q "$source_commit"
git -C "$source_dir" diff --quiet "$source_commit" --
patch -s -d "$source_dir" -p1 < "$recipe_dir/tcc-ascension-version.patch"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure --prefix=/usr --extra-cflags="$CFLAGS"
make -j2
make DESTDIR="$stage_dir" install
install -Dm644 "$source_dir/COPYING" "$stage_dir/usr/share/licenses/tcc/LICENSE"

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
linux_output=$(AXON_TEST_SYSNAME=Linux LD_PRELOAD="$work_dir/uname-override.so" "$stage_dir/usr/bin/tcc" -v 2>&1)
ascension_output=$(AXON_TEST_SYSNAME=Ascension LD_PRELOAD="$work_dir/uname-override.so" "$stage_dir/usr/bin/tcc" -v 2>&1)
grep -q '0\.9\.28rc' <<< "$linux_output"
grep -q '(x86_64 Linux)' <<< "$linux_output"
grep -q '(x86_64 Ascension)' <<< "$ascension_output"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
