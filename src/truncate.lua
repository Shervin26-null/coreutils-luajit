local ffi = require("ffi")

local VERSION = "luajit-coreutils truncate 0.1"

ffi.cdef[[
int truncate(const char *path, long long length);
int stat(const char *path, void *buf);
]]

local opts = {
    size = nil,
    no_create = false,
    reference = nil,
    io_blocks = false
}

local files = {}

local function parse_size(s)
    local sign = s:sub(1,1)
    local modifier = nil

    if sign == "+" or sign == "-" or sign == "<" or sign == ">" or sign == "/" or sign == "%" then
        modifier = sign
        s = s:sub(2)
    end

    local n, unit = s:match("^(%d+)(.*)$")

    if not n then
        error("truncate: invalid size")
    end

    n = tonumber(n)

    local mult = {
        [""] = 1,
        K = 1024,
        M = 1024^2,
        G = 1024^3,
        T = 1024^4,
        P = 1024^5,
        E = 1024^6,
        Z = 1024^7,
        Y = 1024^8,
        R = 1024^9,
        Q = 1024^10,

        KB = 1000,
        MB = 1000^2,
        GB = 1000^3,
        TB = 1000^4,
        PB = 1000^5,
        EB = 1000^6,
        ZB = 1000^7,
        YB = 1000^8,
        RB = 1000^9,
        QB = 1000^10,

        KiB = 1024,
        MiB = 1024^2,
        GiB = 1024^3,
        TiB = 1024^4,
        PiB = 1024^5,
        EiB = 1024^6,
        ZiB = 1024^7,
        YiB = 1024^8
    }

    local m = mult[unit]

    if not m then
        error("truncate: invalid unit")
    end

    return n * m, modifier
end


local args = {...}

local i = 1
while i <= #args do
    local a = args[i]

    if a == "--help" then
        print([[
Usage: truncate OPTION... FILE...
  -c, --no-create
  -r, --reference=RFILE
  -s, --size=SIZE
  -o, --io-blocks
      --help
      --version
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-c" or a == "--no-create" then
        opts.no_create = true

    elseif a == "-o" or a == "--io-blocks" then
        opts.io_blocks = true

    elseif a == "-s" then
        i = i + 1
        opts.size = parse_size(args[i])

    elseif a:match("^%-%-size=") then
        opts.size = parse_size(a:match("^%-%-size=(.*)$"))

    elseif a == "-r" then
        i = i + 1
        opts.reference = args[i]

    elseif a:match("^%-%-reference=") then
        opts.reference = a:match("^%-%-reference=(.*)$")

    else
        files[#files+1] = a
    end

    i = i + 1
end

local function get_size(path)
    local f = io.open(path,"rb")

    if not f then
        return nil
    end

    local size = f:seek("end")
    f:close()

    return size
end


if opts.reference then
    local size = get_size(opts.reference)

    if not size then
        error("truncate: cannot stat reference")
    end

    opts.size = size
end


for _,file in ipairs(files) do

    if opts.no_create then
        local f = io.open(file,"rb")

        if not f then
            goto continue
        end

        f:close()
    end


    local size = opts.size

    local modifier = opts.size_modifier

    local ret = ffi.C.truncate(file,size)

    if ret ~= 0 then
        io.stderr:write(
            "truncate: failed: ",
            file,
            "\n"
        )
        os.exit(1)
    end

    ::continue::
end
