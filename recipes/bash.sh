#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$recipe_dir/.." && pwd)
work_dir=$(mktemp -d)
source_archive="$work_dir/bash-5.3.tar.gz"
source_url="https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz"
source_sha256="0d5cd86965f869a26cf64f4b71be7b96f90a3ba8b3d74e27e8e9d9d5550f31ba"
patch_sha256=(
    1f608434364af86b9b45c8b0ea3fb3b165fb830d27697e6cdfc7ac17dee3287f
    e385548a00130765ec7938a56fbdca52447ab41fabc95a25f19ade527e282001
    f245d9c7dc3f5a20d84b53d249334747940936f09dc97e1dcb89fc3ab37d60ed
    9591d245045529f32f0812f94180b9d9ce9023f5a765c039b852e5dfc99747d0
    cca1ef52dbbf433bc98e33269b64b2c814028efe2538be1e2c9a377da90bc99d
    29119addefed8eff91ae37fd51822c31780ee30d4a28376e96002706c995ff10
    c0976bbfffa1453c7cfdd62058f206a318568ff2d690f5d4fa048793fa3eb299
    097cd723cbfb8907674ac32214063a3fd85282657ec5b4e544d2c0f719653fb4
    eee30fe78a4b0cb2fe20e010e00308899cfc613e0774ebb3c8557a1552f24f8c
    cf76f1cce2ea300c18bff9f002d21f280cc931acd17c28518110b93fe6e72569
    0298df8f5ea2a31d3be43ed7d269c5b3c7c342dd5b570bea7f64d66dcbbe7531
    d71379b39bebaedaf123414414e77fb458a0a43b9ad3116594c6df7ca6754573
    042f9cda967e24bf4211944697441e93d06ff42b4b998629a98a1b249279f200
    bd4360b401d38507e358783dcad8536a99c6789f0d3a5bd0cfb8c4a34144696c
    55b79ceee2fc27f6767eed697e939a7eb2fe2a28c01556bd75f18d581014f46e
)
source_dir="$work_dir/bash-5.3"
stage_dir="$work_dir/stage"
output="$repo_root/pkgs/bash-5.3.15-x86_64.tar.gz"

trap 'rm -rf "$work_dir"' EXIT

curl -fL --retry 2 -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_sha256" "$source_archive" | sha256sum -c -
tar -xzf "$source_archive" -C "$work_dir"
for n in $(seq 1 15); do
    patch_name=$(printf 'bash53-%03d' "$n")
    patch_file="$work_dir/$patch_name"
    curl -fL --retry 2 -o "$patch_file" "https://ftp.gnu.org/gnu/bash/bash-5.3-patches/$patch_name"
    printf '%s  %s\n' "${patch_sha256[$((n - 1))]}" "$patch_file" | sha256sum -c -
    patch -s -d "$source_dir" -p0 < "$patch_file"
done
grep -q '^#define PATCHLEVEL 15$' "$source_dir/patchlevel.h"
source "$recipe_dir/build-env.sh"

cd "$source_dir"
./configure --prefix=/usr --enable-nls CFLAGS="$CFLAGS"
make -j2
make install DESTDIR="$stage_dir"
make -C examples/loadables install-supported DESTDIR="$stage_dir"

mkdir -p "$repo_root/pkgs"
(
    cd "$stage_dir"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf - usr |
        gzip -n > "$output"
)
printf 'Built %s (%s bytes)\n' "$output" "$(stat -c '%s' "$output")"
