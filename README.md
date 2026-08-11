# coreutils-luajit

A LuaJIT-based reimplementation of Unix command-line utilities inspired by GNU Coreutils.

## Status

This project is currently under active development.

More commands, features, optimizations, and GNU Coreutils compatibility improvements will be added over time.

The goal is to provide lightweight, fast, portable implementations of common Unix utilities using LuaJIT.

## Inspiration

This project is inspired by GNU Coreutils.

GNU Coreutils provides essential Unix utilities such as:

- cp
- cat
- chmod
- date
- head
- tail
- sort
- uniq
- wc
- and many more

coreutils-luajit is an independent implementation written from scratch in LuaJIT.

It does not use GNU Coreutils source code.

## Implemented Commands

Currently implemented:

basename.lua cat.lua chmod.lua cp.lua cut.lua date.lua dirname.lua echo.lua env.lua false.lua head.lua hostname.lua ln.lua mkdir.lua mv.lua printenv.lua printf.lua pwd.lua readlink.lua realpath.lua rm.lua seq.lua sleep.lua sort.lua tail.lua touch.lua true.lua uname.lua uniq.lua wc.lua which.lua whoami.lua yes.lua

More commands will be added later.

## Dependencies

### Runtime

Required:

- LuaJIT 2.1+

### Build

Required:

- LuaJIT development headers
- C compiler (GCC or Clang)
- Make

LuaJIT headers include:

lua.h lauxlib.h lualib.h luaconf.h

`lauxlib.h` is provided by Lua/LuaJIT development packages.

Optional:

- LuaRocks
- luastatic

## Installing Dependencies

### Arch Linux

```bash
sudo pacman -S luajit luarocks base-devel
luarocks install luastatic

Debian / Ubuntu

sudo apt update
sudo apt install \
luajit \
libluajit-5.1-dev \
build-essential \
luarocks

luarocks install luastatic

Fedora

sudo dnf install \
luajit \
luajit-devel \
gcc \
make \
luarocks

luarocks install luastatic

Alpine Linux

sudo apk add \
luajit \
luajit-dev \
build-base \
luarocks

luarocks install luastatic

Gentoo

sudo emerge \
dev-lang/luajit \
dev-util/luarocks \
sys-devel/gcc \
sys-devel/make

luarocks install luastatic

Termux (Android)

pkg install \
luajit \
clang \
make \
luarocks

luarocks install luastatic

Build

Clone:

git clone https://github.com/YOUR_USERNAME/coreutils-luajit.git
cd coreutils-luajit

Build everything:

make all

Build a single command:

make cp

Example:

make sort
make wc
make tail

Clean build files:

make clean

Install

Install all compiled commands:

make install

By default commands are installed to:

~/.local/bin

Add it to your PATH.

Bash

echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

Zsh

echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

Verify:

cp --version
wc --help
sort --help

Manual Usage

Commands can also be executed directly:

luajit src/cp.lua file1 file2

Standalone Binaries

Using luastatic:

luastatic src/cp.lua \
-I$PREFIX/include/luajit-2.1 \
-L$PREFIX/lib \
-luajit-5.1 \
-lm \
-o cp

Development

This project is actively developed.

Future improvements:

More GNU-compatible options

Better error handling

Performance optimizations

Recursive operations

More utilities

Improved portability


Contributions and improvements are welcome.

License

Licensed under the GNU General Public License v3.0.

See:

LICENSE

Copyright (C) 2026
