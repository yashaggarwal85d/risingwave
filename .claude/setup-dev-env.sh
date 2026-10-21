#!/usr/bin/env bash
# Installs system packages and dev tools needed to build and test RisingWave (Debian/Ubuntu).
set -euo pipefail
SUDO=$([ "$(id -u)" -eq 0 ] && echo "" || echo sudo)
$SUDO apt-get update -qq
DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq make build-essential cmake protobuf-compiler \
  curl postgresql-client tmux lld pkg-config libssl-dev libsasl2-dev libblas-dev liblapack-dev libomp-dev parallel
command -v rustup >/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# The pinned nightly (rust-toolchain) needs rustfmt and clippy for `./risedev c`.
rustup component add rustfmt clippy
command -v cargo-binstall >/dev/null || curl -L --proto '=https' --tlsv1.2 -sSf \
  https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
for tool in cargo-make@~0.37 cargo-nextest cargo-hakari cargo-sort typos-cli sqllogictest-bin; do
  cargo binstall -y --locked "$tool"
done
