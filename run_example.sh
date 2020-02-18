#!/usr/bin/env bash

# Examples only run on a nRF52-DK board

set -eux

cargo build --release --target=riscv32imac-unknown-none-elf --example "$1"


elf_file_name="target/tab/$1/rv32imac.elf"
tab_file_name="target/tab/$1.tab"

mkdir -p "target/tab/$1"
cp "target/riscv32imac-unknown-none-elf/release/examples/$1" "$elf_file_name"

elf2tab -n "$1" -o "$tab_file_name" "$elf_file_name" --stack 2048 --app-heap 512 --kernel-heap 1024

