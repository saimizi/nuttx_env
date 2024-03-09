#!/usr/bin/bash

BOARD_CONF?=esp32-devkitc:nsh
PORT?=/dev/ttyUSB0

all: build

nuttx/.config:
	echo $(BOARD_CONF)
	cd nuttx;tools/configure.sh -l -E  -a ../nuttx-apps/ $(BOARD_CONF)

esp-bins:
	mkdir esp-bins

esp-bins/bootloader-esp32.bin: esp-bins
	curl -L \
		-s \
		https://github.com/espressif/esp-nuttx-bootloader/releases/download/latest/bootloader-esp32.bin \
		-o esp-bins/bootloader-esp32.bin

esp-bins/partition-table-esp32.bin : esp-bins
	curl -L \
		-s \
		https://github.com/espressif/esp-nuttx-bootloader/releases/download/latest/partition-table-esp32.bin \
		-o esp-bins/partition-table-esp32.bin


build-bootloader:
	docker run --rm --user $(id -u):$(id -g) -v $(PWD)/esp-nuttx-bootloader:/work -w /work espressif/idf:latest ./build_idfboot.sh -c esp32


configure: nuttx/.config

build: nuttx/.config
	make -C nuttx

menuconfig:
	make menuconfig -C nuttx

download-all: esp-bins/bootloader-esp32.bin esp-bins/partition-table-esp32.bin
	make -C nuttx flash ESPTOOL_PORT=$(PORT) ESPTOOL_BAUD=115200 ESPTOOL_BINDIR=../esp-bins


download-nuttx:
	make -C nuttx flash ESPTOOL_PORT=$(PORT) ESPTOOL_BAUD=115200

list-esp32-config:
	./nuttx/tools/configure.sh -L | grep esp32-

clean:
	make clean -C nuttx

distclean: clean
	rm nuttx/.config 2>/dev/null || true
	make distclean -C nuttx

