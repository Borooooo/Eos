# made by claude too lazy to write this makefile shi
SHELL := /usr/bin/env bash

.PHONY: help host-prereqs host-check layout fetch binutils gcc1 headers glibc gcc2 toolchain kernel gui-core gui-wayland gui-input weston gui-stack rootfs run iso run-iso gui-test pkg-test test-pkg test-security all

help:
	@echo "Eos build targets:"
	@echo "  host-prereqs  Install required packages on WSL host"
	@echo "  host-check    Validate host tools"
	@echo "  layout        Create work directories"
	@echo "  fetch         Download and extract upstream sources"
	@echo "  toolchain     Build binutils, gcc stage1, headers, glibc, gcc stage2"
	@echo "  kernel        Build Linux kernel"
	@echo "  gui-core      Build core graphics and keyboard libraries"
	@echo "  gui-wayland   Build native Wayland libraries and protocols"
	@echo "  gui-input     Build input/session stack for DRM Weston"
	@echo "  weston        Build native Weston compositor"
	@echo "  gui-stack     Build full native Weston stack"
	@echo "  rootfs        Build busybox initramfs"
	@echo "  iso           Build bootable ISO (GRUB + kernel + initramfs)"
	@echo "  run-iso       Boot ISO image in QEMU"
	@echo "  gui-test      Boot VM and attempt minimal GUI bootstrap with tty fallback"
	@echo "  pkg-test      Build and install sample eospkg package"
	@echo "  test-pkg      Run eospkg smoke tests"
	@echo "  test-security Run repo/index/installer security tests"
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
	./scripts/build/40_build_gcc_stage1.sh

headers:
	./scripts/build/30_install_kernel_headers.sh

glibc:
	./scripts/build/50_build_glibc.sh

gcc2:
	./scripts/build/60_build_gcc_stage2.sh

toolchain: binutils gcc1 headers glibc gcc2

kernel:
	./scripts/build/70_build_kernel.sh

gui-core: fetch toolchain
	./scripts/build/76_build_gui_core.sh

gui-wayland: gui-core
	./scripts/build/77_build_wayland_stack.sh

gui-input: gui-wayland
	./scripts/build/78_build_input_stack.sh

weston: gui-input
	./scripts/build/79_build_weston.sh

gui-stack: weston

rootfs: gui-stack
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

test-security:
	python3 -m unittest -v tests/test_repo_index.py tests/test_eospkg_repo.py tests/test_install_rootfs.py

run:
	./scripts/build/90_run_qemu.sh

iso: kernel rootfs
	./scripts/build/95_build_iso.sh

run-iso:
	./scripts/build/96_run_qemu_iso.sh

gui-test: kernel rootfs
	./scripts/gui/run_weston_test.sh

all: layout fetch toolchain kernel rootfs
