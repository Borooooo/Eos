EOS_WORKDIR ?= $(HOME)/eos-work
TARGET ?= x86_64-eos-linux-gnu

CXX := $(EOS_WORKDIR)/tools/bin/$(TARGET)-g++
SYSROOT := $(EOS_WORKDIR)/sysroot

CXXFLAGS := --sysroot=$(SYSROOT) -std=c++20 -O2 -Wall -Wextra -static

TARGET_BIN := eos-init

all: $(TARGET_BIN)

$(TARGET_BIN): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<
	@echo "===================================="
	@echo "done $@!"


clean:
	rm -f $(TARGET_BIN)

.PHONY: all clean
