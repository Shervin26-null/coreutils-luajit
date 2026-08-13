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

basename.lua  env.lua       ln.lua        pwd.lua       tee.lua       uniq.lua
cat.lua       expand.lua    ls.lua        readlink.lua  test.lua      wc.lua
chmod.lua     false.lua     mkdir.lua     realpath.lua  touch.lua     which.lua
cp.lua        fold.lua      mv.lua        rm.lua        tr.lua        whoami.lua
cut.lua       grep.lua      nl.lua        rmdir.lua     true.lua      yes.lua
date.lua      head.lua      nproc.lua     seq.lua       truncate.lua
dd.lua        hostname.lua  paste.lua     sleep.lua     tty.lua
dirname.lua   id.lua        printenv.lua  sort.lua      uname.lua
echo.lua      install.lua   printf.lua    tail.lua      unexpand.lua
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
```
### Debian / Ubuntu
```bash
sudo apt update
sudo apt install \
luajit \
libluajit-5.1-dev \
build-essential \
luarocks

luarocks install luastatic
```
### Fedora
```bash
sudo dnf install \
luajit \
luajit-devel \
gcc \
make \
luarocks

luarocks install luastatic
```
### Alpine Linux
```bash
sudo apk add \
luajit \
luajit-dev \
build-base \
luarocks

luarocks install luastatic
```
### Gentoo
```bash
sudo emerge \
dev-lang/luajit \
dev-util/luarocks \
sys-devel/gcc \
sys-devel/make

luarocks install luastatic
```
### Termux (Android)
```bash
pkg install \
luajit \
clang \
make \
luarocks

luarocks install luastatic
```
Build

Clone:
```bash
git clone https://github.com/Shervin26-null/coreutils-luajit.git
cd coreutils-luajit
```
Build everything:
```bash
make
```
Build a single command:
```bash
make cp
```
Example:
```bash
make sort
make wc
make tail
```
Clean build files:
```bash
make clean
```
Install

Install all compiled commands:
```bash
make install-bin
```
By default commands are installed to:
```bash
~/.local/bin
```
Add it to your PATH.

Bash
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
Zsh
```zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
Verify:
```bash
cp --version
wc --help
sort --help
```
Manual Usage

Commands can also be executed directly:
```bash
luajit src/cp.lua file1 file2
```
Standalone Binaries

Using luastatic:
```bash
luastatic src/cp.lua \
-I$PREFIX/include/luajit-2.1 \
-L$PREFIX/lib \
-luajit-5.1 \
-lm \
-o cp
```
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
