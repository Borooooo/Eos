# made by claude too lazy to write this makefile shi
SHELL := /usr/bin/env bash

.PHONY: help host-prereqs host-check layout fetch binutils gcc1 headers glibc gcc2 toolchain kernel rootfs run pkg-test test-pkg all

help:
	@echo "Eos build targets:"
	@echo "  host-prereqs  Install required packages on WSL host"
	@echo "  host-check    Validate host tools"
	@echo "  layout        Create work directories"
	@echo "  fetch         Download and extract upstream sources"
	@echo "  toolchain     Build binutils, gcc stage1, headers, glibc, gcc stage2"
	@echo "  kernel        Build Linux kernel"
	@echo "  rootfs        Build busybox initramfs"
	@echo "  pkg-test      Build and install sample eospkg package"
	@echo "  test-pkg      Run eospkg smoke tests"
	@echo "  run           Boot kernel + initramfs in QEMU"

host-prereqs:
	./scripts/host/install_wsl_prereqs.sh

host-check:
	./scripts/host/check_host.sh

layout:
	./scripts/build/00_layout.sh

fetch:
	./scripts/build/10_fetch_sources.sh

binutils:
	./scripts/build/20_build_binutils.sh

gcc1:
	./scripts/build/30_build_gcc_stage1.sh

headers:
	./scripts/build/40_install_kernel_headers.sh

glibc:
	./scripts/build/50_build_glibc.sh

gcc2:
	./scripts/build/60_build_gcc_stage2.sh

toolchain: binutils gcc1 headers glibc gcc2

kernel:
	./scripts/build/70_build_kernel.sh

rootfs:
	./scripts/build/80_build_busybox_rootfs.sh

pkg-test:
	python3 pkg/eospkg.py build --name hello --version 0.1.0 --input-dir pkg/example_payload --output pkg/out
	python3 pkg/eospkg.py info --package pkg/out/hello-0.1.0.eospkg
	python3 pkg/eospkg.py install pkg/out/hello-0.1.0.eospkg --root "$$HOME/eos-root"
	python3 pkg/eospkg.py list --root "$$HOME/eos-root"
	python3 pkg/eospkg.py verify --root "$$HOME/eos-root"
	python3 pkg/eospkg.py info --name hello --root "$$HOME/eos-root"
	python3 pkg/eospkg.py remove hello --root "$$HOME/eos-root"

test-pkg:
	python3 -m unittest -v tests/test_eospkg_smoke.py

run:
	./scripts/build/90_run_qemu.sh

all: layout fetch toolchain kernel rootfs
