local ffi = require("ffi")

local VERSION = "luajit-coreutils printf 0.1"

local function usage()
    io.write([[
Usage: printf FORMAT [ARGUMENT]...

Print ARGUMENT(s) according to FORMAT.
]])
end

local args = {}
for i = 1, #arg do
    args[#args + 1] = arg[i]
end

if args[1] == "--help" then
    usage()
    os.exit(0)
end

if args[1] == "--version" then
    print(VERSION)
    os.exit(0)
end

if #args == 0 then
    os.exit(0)
end

local fmt = table.remove(args, 1)

local index = 1

fmt = fmt:gsub("%%b", function()
    local v = tonumber(args[index]) or 0
    index = index + 1
    return tostring(v):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
end)

fmt = fmt:gsub("\\([\\'\"abfnrtv])", {
    ["\\"]="\\",
    ["'"]="'",
    ['"']='"',
    a="\a",
    b="\b",
    f="\f",
    n="\n",
    r="\r",
    t="\t",
    v="\v",
})

fmt = fmt:gsub("\\([0-7][0-7]?[0-7]?)", function(o)
    return string.char(tonumber(o, 8))
end)

fmt = fmt:gsub("%%([%-%+ #0]*)(%d*)%.?(%d*)([diouxXeEfFgGsc])", function(flags, width, precision, spec)
    local v = args[index] or ""
    index = index + 1

    width = tonumber(width) or 0
    precision = tonumber(precision)

    if spec == "s" then
        if precision then
            v = v:sub(1, precision)
        end
        return string.format("%"..flags..width.."s", v)

    elseif spec == "c" then
        return string.char(tonumber(v) or 0)

    else
        local f = "%" .. flags .. width
        if precision then
            f = f .. "." .. precision
        end
        f = f .. spec

        return string.format(f, tonumber(v) or 0)
    end
end)

io.write(fmt)
