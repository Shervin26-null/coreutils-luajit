#!/usr/bin/env luajit

local ffi = require("ffi")

if arg[1] == "/" or arg[1] == "//" then
    io.write("/\n")
    os.exit(0)
end

ffi.cdef[[
ssize_t write(int fd, const void *buf, size_t count);
]]

local C = ffi.C

local VERSION = "luajit-coreutils dirname 0.1"

local function out(s)
    C.write(1, s, #s)
end

local function err(s)
    C.write(2, s, #s)
end

if arg[1] == "--version" then
    out(VERSION .. "\n")
    os.exit(0)
end

if arg[1] == "--help" then
    out("Usage: dirname NAME\n")
    os.exit(0)
end

if not arg[1] then
    err("dirname: missing operand\n")
    os.exit(1)
end

local path = arg[1]

path = path:gsub("/+$", "")

local dir = path:match("^(.*)/[^/]*$")

if not dir or dir == "" then
    out(".\n")
else
    out(dir .. "\n")
end
