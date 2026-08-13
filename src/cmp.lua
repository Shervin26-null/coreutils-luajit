local VERSION = "cmp (coreutils-luajit) 0.1"

local ffi = require("ffi")

ffi.cdef[[
int memcmp(const void *s1, const void *s2, size_t n);
]]

local opts = {
    verbose = false,
    print_bytes = false,
    quiet = false,
    limit = nil,
    skip1 = 0,
    skip2 = 0
}

local files = {}

local function parse_size(s)
    local n, u = s:match("^(%d+)(.*)$")
    if not n then
        error("cmp: invalid size: " .. s)
    end

    n = tonumber(n)

    local m = {
        [""] = 1,
        kB = 1000,
        K = 1024,
        MB = 1000000,
        M = 1024^2,
        GB = 1000000000,
        G = 1024^3,
        TB = 1000000000000,
        T = 1024^4
    }

    if not m[u] then
        error("cmp: invalid suffix")
    end

    return n * m[u]
end

local function help()
    print([=[
Usage: cmp [OPTION]... FILE1 [FILE2 [SKIP1 [SKIP2]]]

Compare two files byte by byte.

  -b, --print-bytes          print differing bytes
  -i, --ignore-initial=SKIP  skip initial bytes
  -l, --verbose              output byte numbers and values
  -n, --bytes=LIMIT          compare at most LIMIT bytes
  -s, --quiet, --silent      suppress output
      --help                 display this help
  -v, --version              output version information

Exit status:
  0 files are identical
  1 files differ
  2 error
]=])
end

local i = 1
while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" or a == "-v" then
        print(VERSION)
        os.exit(0)

    elseif a == "-b" or a == "--print-bytes" then
        opts.print_bytes = true

    elseif a == "-l" or a == "--verbose" then
        opts.verbose = true

    elseif a == "-s" or a == "--quiet" or a == "--silent" then
        opts.quiet = true

    elseif a == "-n" or a == "--bytes" then
        i = i + 1
        opts.limit = parse_size(arg[i])

    elseif a:match("^--bytes=") then
        opts.limit = parse_size(a:match("=(.*)"))

    elseif a == "-i" or a == "--ignore-initial" then
        i = i + 1
        local x,y = arg[i]:match("^(%d+):(%d+)$")
        if x then
            opts.skip1 = tonumber(x)
            opts.skip2 = tonumber(y)
        else
            opts.skip1 = parse_size(arg[i])
            opts.skip2 = opts.skip1
        end

    elseif a:match("^--ignore-initial=") then
        local v = a:match("=(.*)")
        local x,y = v:match("^(%d+):(%d+)$")
        if x then
            opts.skip1 = parse_size(x)
            opts.skip2 = parse_size(y)
        else
            opts.skip1 = parse_size(v)
            opts.skip2 = opts.skip1
        end

    else
        files[#files+1] = a
    end

    i = i + 1
end

if #files < 1 then
    help()
    os.exit(2)
end

local f1 = io.stdin
local f2 = io.stdin

if files[1] ~= "-" then
    f1 = io.open(files[1], "rb")
end

if not f1 then
    io.stderr:write("cmp: cannot open ", files[1], "\n")
    os.exit(2)
end

if files[2] and files[2] ~= "-" then
    f2 = io.open(files[2], "rb")
else
    f2 = io.stdin
end

if not f2 then
    io.stderr:write("cmp: cannot open ", files[2], "\n")
    os.exit(2)
end

f1:seek("set", opts.skip1)
f2:seek("set", opts.skip2)



local pos = 0
local line = 1
local chunk = 1024 * 1024

while true do
    if opts.limit and pos >= opts.limit then
        break
    end

    local size = chunk

    if opts.limit and pos + size > opts.limit then
        size = opts.limit - pos
    end

    local a = f1:read(size)
    local b = f2:read(size)

    if not a and not b then
        break
    end

    if not a or not b or #a ~= #b then
        if not opts.quiet then
            print(files[1] .. " " .. (files[2] or "stdin") .. " differ: char " .. (pos + math.min(#(a or ""), #(b or "")) + 1))
        end
        os.exit(1)
    end

    local pa = ffi.cast("const uint8_t*", a)
    local pb = ffi.cast("const uint8_t*", b)

    if ffi.C.memcmp(pa, pb, #a) ~= 0 then
        for i = 0, #a - 1 do
            if a:byte(i+1) ~= b:byte(i+1) then
                if not opts.quiet then
                    print(string.format(
                        "%s %s differ: char %d, line %d",
                        files[1],
                        files[2] or "stdin",
                        pos+i+1,
                        line
                    ))
                end
                os.exit(1)
            end
        end
    end

    pos = pos + #a
end

os.exit(0)


