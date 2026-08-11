#!/usr/bin/env luajit

local ffi = require("ffi")

ffi.cdef[[
unsigned int sleep(unsigned int seconds);
int usleep(unsigned int usec);
int nanosleep(const struct timespec *req, struct timespec *rem);

struct timespec {
    long tv_sec;
    long tv_nsec;
};
]]

local C = ffi.C

local VERSION = "luajit-coreutils sleep 0.1"

local function die(msg)
    io.stderr:write("sleep: " .. msg .. "\n")
    os.exit(1)
end

local function help()
    io.write([[
Usage: sleep NUMBER[SUFFIX]...
Pause for NUMBER seconds.

Suffixes:
  s seconds
  m minutes
  h hours
  d days

      --help     display this help and exit
      --version  output version information and exit
]])
end

local function parse_time(s)
    local num, suffix = s:match("^([+-]?[%d%.]+)([smhd]?)$")

    if not num then
        die("invalid time interval '" .. s .. "'")
    end

    local n = tonumber(num)

    if not n or n < 0 then
        die("invalid time interval '" .. s .. "'")
    end

    if suffix == "m" then
        n = n * 60
    elseif suffix == "h" then
        n = n * 3600
    elseif suffix == "d" then
        n = n * 86400
    end

    return n
end

local total = 0

for i = 1, #arg do
    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    else
        total = total + parse_time(a)
    end
end

if #arg == 0 then
    die("missing operand")
end

local sec = math.floor(total)
local nsec = math.floor((total - sec) * 1000000000)

local req = ffi.new("struct timespec")
req.tv_sec = sec
req.tv_nsec = nsec

while C.nanosleep(req, nil) ~= 0 do
end

os.exit(0)
