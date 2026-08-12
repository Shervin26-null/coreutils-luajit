SRCDIR := src
INSTALLBINS := $(HOME)/.local/bin

CC ?= cc

CFLAGS ?= -O3 -march=native -mtune=native -flto \
          -fomit-frame-pointer -ffunction-sections -fdata-sections

LDFLAGS ?= -Wl,--gc-sections -Wl,-O3

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(TERMUX_VERSION),)
OS := $(UNAME_S)
else
OS := Android-Termux
endif

ifeq ($(UNAME_M),aarch64)
ARCH := arm64
else ifeq ($(UNAME_M),arm64)
ARCH := arm64
else ifeq ($(UNAME_M),x86_64)
ARCH := x86_64
else ifeq ($(UNAME_M),amd64)
ARCH := x86_64
else ifeq ($(UNAME_M),riscv64)
ARCH := riscv64
else
ARCH := $(UNAME_M)
endif


# LuaJIT detection
LUAJIT_CFLAGS := $(shell pkg-config --cflags luajit 2>/dev/null)
LUAJIT_LIBS := $(shell pkg-config --libs luajit 2>/dev/null)

ifeq ($(strip $(LUAJIT_CFLAGS)),)
LUAJIT_CFLAGS := -I/usr/include/luajit-2.1
endif

ifeq ($(strip $(LUAJIT_LIBS)),)
LUAJIT_LIBS := -lluajit-5.1
endif


SOURCES := $(wildcard $(SRCDIR)/*.lua)
TARGETS := $(patsubst $(SRCDIR)/%.lua,%,$(SOURCES))


.DEFAULT_GOAL := build


.PHONY: all build clean install check info setup-path

all: build


check:
	@command -v luastatic >/dev/null 2>&1 || \
		(echo "luastatic not found"; exit 1)


build: check $(TARGETS)
	@echo "Built for $(OS) $(ARCH)"


# Compile lua files from src into root binaries
# Explicitly avoids collision with make install
$(filter-out install,$(TARGETS)): %: $(SRCDIR)/%.lua
	CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
	luastatic $< \
		$(LUAJIT_CFLAGS) \
		$(LUAJIT_LIBS) \
		-lm \
		-o $@
	@strip -s $@ 2>/dev/null || true


# install command binary
install: $(SRCDIR)/install.lua
	CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
	luastatic $< \
		$(LUAJIT_CFLAGS) \
		$(LUAJIT_LIBS) \
		-lm \
		-o $@
	@strip -s $@ 2>/dev/null || true


# install compiled binaries
install-bin: build setup-path
	mkdir -p $(INSTALLBINS)
	$(shell command -v install) -m755 $(TARGETS) $(INSTALLBINS)


clean:
	rm -f $(TARGETS)
	rm -f *.luastatic.c
	rm -f *.o


info:
	@echo "OS: $(OS)"
	@echo "Architecture: $(ARCH)"
	@echo "LuaJIT CFLAGS: $(LUAJIT_CFLAGS)"
	@echo "LuaJIT LIBS: $(LUAJIT_LIBS)"
	@echo "Compiler: $(CC)"


SHELL_NAME := $(notdir $(SHELL))

ifeq ($(SHELL_NAME),zsh)
SHELL_RC := $(HOME)/.zshrc
else ifeq ($(SHELL_NAME),bash)
SHELL_RC := $(HOME)/.bashrc
else
SHELL_RC := $(HOME)/.profile
endif


setup-path:
	@if ! grep -q '\.local/bin' $(SHELL_RC) 2>/dev/null; then \
		printf '\nexport PATH="$$HOME/.local/bin:$$PATH"\n' >> $(SHELL_RC); \
		echo "Added ~/.local/bin"; \
	else \
		echo "~/.local/bin already configured"; \
	fi
