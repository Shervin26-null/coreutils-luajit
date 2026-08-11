#!/usr/bin/env luajit

local ffi = require("ffi")

ffi.cdef[[
int snprintf(char *str, unsigned long size, const char *fmt, ...);
]]

local C = ffi.C

local VERSION = "luajit-coreutils seq 0.1"

local function die(msg)
    io.stderr:write("seq: " .. msg .. "\n")
    os.exit(1)
end

local function help()
    io.write([[
Usage: seq [OPTION]... LAST
  or:  seq [OPTION]... FIRST LAST
  or:  seq [OPTION]... FIRST INCREMENT LAST

Print numbers from FIRST to LAST, in steps of INCREMENT.

  -f, --format=FORMAT      use printf style FORMAT
  -s, --separator=STRING  use STRING to separate numbers
  -w, --equal-width        equalize width by padding with leading zeroes
      --help               display this help and exit
      --version            output version information and exit
]])
end

local function version()
    io.write(VERSION .. "\n")
end

local function parse_num(s)
    if not s:match("^[+-]?%d*%.?%d+[eE]?[+-]?%d*$") then
        die("invalid floating point argument: '" .. s .. "'")
    end

    local n = tonumber(s)

    if not n or n ~= n then
        die("invalid floating point argument: '" .. s .. "'")
    end

    return n
end

local function printf(fmt, n)
    local buf = ffi.new("char[1024]")
    local r = C.snprintf(buf, 1024, fmt, n)

    if r < 0 then
        die("invalid format")
    end

    return ffi.string(buf)
end

local separator = "\n"
local format = nil
local equal_width = false

local nums = {}

local i = 1
while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        version()
        os.exit(0)

    elseif a == "-w" or a == "--equal-width" then
        equal_width = true

    elseif a == "-s" then
        i = i + 1
        if not arg[i] then
            die("option requires an argument -- 's'")
        end
        separator = arg[i]

    elseif a:match("^--separator=") then
        separator = a:sub(13)

    elseif a == "-f" then
        i = i + 1
        if not arg[i] then
            die("option requires an argument -- 'f'")
        end
        format = arg[i]

    elseif a:match("^--format=") then
        format = a:sub(10)

    elseif a == "--" then
        for j=i+1,#arg do
            nums[#nums+1]=arg[j]
        end
        break

    elseif a:sub(1,1) == "-" and not a:match("^%-?%d") then
        die("invalid option: " .. a)

    else
        nums[#nums+1]=a
    end

    i=i+1
end


if #nums == 0 then
    die("missing operand")
end

if #nums > 3 then
    die("extra operand '" .. nums[4] .. "'")
end


local first, step, last

if #nums == 1 then
    first = 1
    step = 1
    last = parse_num(nums[1])

elseif #nums == 2 then
    first = parse_num(nums[1])
    step = 1
    last = parse_num(nums[2])

else
    first = parse_num(nums[1])
    step = parse_num(nums[2])
    last = parse_num(nums[3])
end


if step == 0 then
    die("invalid Zero increment value")
end


if not format then
    local precision = 0

    for _,v in ipairs(nums) do
        local p = v:match("%.(%d+)")
        if p and #p > precision then
            precision = #p
        end
    end

    if precision > 0 then
        format = "%." .. precision .. "f"
    else
        format = "%g"
    end
end


local values = {}

local n = first

if step > 0 then
    while n <= last do
        values[#values+1] = printf(format, n)
        n = n + step
    end
else
    while n >= last do
        values[#values+1] = printf(format, n)
        n = n + step
    end
end


if equal_width then
    local width = 0

    for _,v in ipairs(values) do
        if #v > width then
            width=#v
        end
    end

    for i,v in ipairs(values) do
        local neg = ""

        if v:sub(1,1) == "-" then
            neg="-"
            v=v:sub(2)
        end

        values[i]=neg .. string.rep("0", width-#neg-#v) .. v
    end
end


io.write(table.concat(values, separator))

if #values > 0 then
    io.write("\n")
end
