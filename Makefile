SRCDIR := src
INSTALLBINS := $(HOME)/.local/bin

# Compiler settings
CC ?= cc

CFLAGS ?= -O3 -march=native -mtune=native -flto -fomit-frame-pointer \
          -ffunction-sections -fdata-sections

LDFLAGS ?= -Wl,--gc-sections -Wl,-O3

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Detect OS
ifeq ($(TERMUX_VERSION),)
    ifeq ($(UNAME_S),Linux)
        OS := Linux
    else
        OS := $(UNAME_S)
    endif
else
    OS := Android-Termux
endif


# Detect architecture
ARCH := unknown

ifeq ($(UNAME_M),x86_64)
    ARCH := x86_64
else ifeq ($(UNAME_M),amd64)
    ARCH := x86_64
else ifeq ($(UNAME_M),i386)
    ARCH := x86
else ifeq ($(UNAME_M),i686)
    ARCH := x86
else ifeq ($(UNAME_M),aarch64)
    ARCH := arm64
else ifeq ($(UNAME_M),arm64)
    ARCH := arm64
else ifeq ($(UNAME_M),armv7l)
    ARCH := arm
else ifeq ($(UNAME_M),riscv64)
    ARCH := riscv64
else ifeq ($(UNAME_M),ppc64le)
    ARCH := ppc64le
endif


# LuaJIT detection
LUAJIT_CFLAGS := $(shell pkg-config --cflags luajit 2>/dev/null)
LUAJIT_LIBS := $(shell pkg-config --libs luajit 2>/dev/null)

# Fallback paths
ifeq ($(strip $(LUAJIT_CFLAGS)),)
    ifneq ($(wildcard /usr/include/luajit-2.1/lauxlib.h),)
        LUAJIT_CFLAGS := -I/usr/include/luajit-2.1
    else ifneq ($(wildcard /usr/local/include/luajit-2.1/lauxlib.h),)
        LUAJIT_CFLAGS := -I/usr/local/include/luajit-2.1
    else ifneq ($(wildcard $(PREFIX)/include/luajit-2.1/lauxlib.h),)
        LUAJIT_CFLAGS := -I$(PREFIX)/include/luajit-2.1
    endif
endif


ifeq ($(strip $(LUAJIT_LIBS)),)
    ifneq ($(wildcard /usr/lib/*/libluajit-5.1.so),)
        LUAJIT_LIBS := -lluajit-5.1
    else ifneq ($(wildcard /usr/local/lib/libluajit-5.1.so),)
        LUAJIT_LIBS := -L/usr/local/lib -lluajit-5.1
    else ifneq ($(wildcard $(PREFIX)/lib/libluajit-5.1.so),)
        LUAJIT_LIBS := -L$(PREFIX)/lib -lluajit-5.1
    else
        LUAJIT_LIBS := -lluajit-5.1
    endif
endif


SOURCES := $(wildcard $(SRCDIR)/*.lua)
TARGETS := $(patsubst $(SRCDIR)/%.lua,%,$(SOURCES))


.DEFAULT_GOAL := all


all: build


check:
	@if ! command -v luastatic >/dev/null 2>&1; then \
		echo "luastatic not found"; \
		if command -v luarocks >/dev/null 2>&1; then \
			luarocks install luastatic; \
		else \
			echo "Install luarocks first"; \
			exit 1; \
		fi; \
	fi


build: check $(TARGETS)
	@echo "Built for $(OS) $(ARCH)"


%: $(SRCDIR)/%.lua
	CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
	luastatic $< \
		$(LUAJIT_CFLAGS) \
		$(LUAJIT_LIBS) \
		-lm \
		-o $@
	@strip -s $@ 2>/dev/null || true


install: build setup-path
	mkdir -p $(INSTALLBINS)
	install -m755 $(TARGETS) $(INSTALLBINS)


clean:
	rm -f $(TARGETS)
	rm -f *.luastatic.c
	rm -f $(SRCDIR)/*.luastatic.c
	rm -f *.o
	rm -f $(SRCDIR)/*.o
	rm -rf data

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
		echo "Added ~/.local/bin to $(SHELL_RC)"; \
	else \
		echo "~/.local/bin already configured"; \
	fi


.PHONY: all build clean install check info setup-path
