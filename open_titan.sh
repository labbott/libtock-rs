#!/usr/bin/env bash

# Examples only run on a nRF52-DK board

set -eux

NAME=$1
FLASH_START=0x20030000
SRAM_START=0x10003400
BASEFLAGS="-C link-arg=-zmax-page-size=0x100 -C link-arg=-Ttarget/tab/$1/riscv32_layout.ld -C relocation-model=static -D warnings"
TOCK_KERNEL=/home/labbott/tock/

build_binary() {
	f_start=$1
	s_start=$2
	cargo clean
	mkdir -p "target/tab/$NAME"
	cp riscv32_layout.ld target/tab/$NAME/
	sed -i s/__FLASH_START__/$f_start/ target/tab/$NAME/riscv32_layout.ld
	sed -i s/__SRAM_START__/$s_start/ target/tab/$NAME/riscv32_layout.ld

	RUSTFLAGS=$BASEFLAGS cargo build --verbose --release --target=riscv32imac-unknown-none-elf --example "$NAME"
#RUSTFLAGS=$FIRST_FLAGS cargo rustc --verbose --release --target=riscv32imac-unknown-none-elf --example "$1"

	elf_file_name="target/tab/$NAME/rv32imac.elf"
	tab_file_name="target/tab/$NAME.tab"

	mkdir -p "target/tab/$NAME"
	cp "target/riscv32imac-unknown-none-elf/release/examples/$NAME" "$elf_file_name"
	elf2tab --verbose -n "$NAME" -o "$tab_file_name" "$elf_file_name" --stack 2048 --app-heap 512 --kernel-heap 2048 &> /tmp/bad
}

build_binary $FLASH_START $SRAM_START

_ACTUAL_HEADER=`cat /tmp/bad | grep header_size | tr -s ' ' | cut -d ' ' -f 4`
_ACTUAL_START=`riscv32-unknown-elf-nm $TOCK_KERNEL/boards/opentitan/target/riscv32imc-unknown-none-elf/release/opentitan.elf | grep start_app_memory | cut -d ' ' -f 1`
echo $_ACTUAL_HEADER
echo $_ACTUAL_START
NEW_FLASH=$FLASH_START+$_ACTUAL_HEADER
NEW_SRAM=0x$_ACTUAL_START

build_binary $NEW_FLASH $NEW_SRAM

