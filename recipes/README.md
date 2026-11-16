# Build recipes

Package recipes belong in this directory and should be named `<package>.sh`. Each recipe should pin its upstream source version and SHA-256 checksum, build into a temporary staging root, and produce the same `usr/` layout used by the archives in `pkgs/`.

Source `build-env.sh` before configuring or compiling. It sets Linux x86-64 as the target and forces generic x86-64-v3 flags for C, C++, Rust, and Go. Do not use `-march=native`, `-march=x86-64-v4`, or compiler auto-detection: these make artifacts depend on the build machine or newer CPU features. The v3 baseline includes AVX2 and requires a v3-capable CPU and operating-system support for AVX state; older PCs may not run these builds.

Ascension is treated as Linux-ABI-compatible, so recipes use the Linux target and do not need a separate architecture build. Packages that need Ascension-specific runtime behavior must preserve or add that behavior in their source patches; the target flags alone do not provide kernel or syscall compatibility.

Pinned source recipes currently cover Bash, coreutils, cJSON, file, htop, jq, Lua, Nano, rsync, strace, tmux, tree, which, and zstd. Each recipe replaces the standard `x86_64` archive only after a successful build and package-specific checks.

Other package archives have not yet been rebuilt. Rust and Go packages need those toolchains; packages with custom outputs or patches need recipes that preserve those interfaces before their existing archives can be replaced.