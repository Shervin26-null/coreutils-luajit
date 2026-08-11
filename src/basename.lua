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

local VERSION = "luajit-coreutils basename 0.1"

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
    out("Usage: basename NAME [SUFFIX]\n")
    os.exit(0)
end

if not arg[1] then
    err("basename: missing operand\n")
    os.exit(1)
end

local path = arg[1]
local suffix = arg[2]

path = path:gsub("/+$", "")

local name = path:match("([^/]+)$") or path

if suffix and suffix ~= "" and name:sub(-#suffix) == suffix then
    name = name:sub(1, -#suffix - 1)
end

out(name .. "\n")
