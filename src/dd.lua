local VERSION = "luajit-coreutils dd 0.1"

local opts = {
    input = "-",
    output = "-",
    bs = 512,
    ibs = 512,
    obs = 512,
    cbs = nil,
    count = nil,
    skip = 0,
    seek = 0,
    status = "full",
    conv = {},
    iflag = {},
    oflag = {}
}


local function parse_list(s)
    local t = {}
    for v in s:gmatch("[^,]+") do
        t[v] = true
    end
    return t
end

local function parse_size(s)
    local n, suffix = s:match("^(%d+)(.*)$")
    n = tonumber(n)

    local mult = {
        c = 1,
        w = 2,
        b = 512,

        kB = 1000,
        MB = 1000000,
        GB = 1000000000,

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

        KiB = 1024,
        MiB = 1024^2,
        GiB = 1024^3
    }

    if suffix:sub(1,1) == "x" then
        suffix=suffix:sub(2)
        n=n*mult[suffix]
        return n
    end

    if suffix == "" then
        return n
    end

    if mult[suffix] then
        return n * mult[suffix]
    end

    error("dd: invalid size: "..s)
end

for _, arg in ipairs({...}) do
    local k,v = arg:match("^(.-)=(.*)$")

    if k == "if" then
        opts.input = v
    elseif k == "of" then
        opts.output = v
    elseif k == "bs" then
        opts.bs = parse_size(v)
        opts.ibs = opts.bs
        opts.obs = opts.bs
    elseif k == "ibs" then
        opts.ibs = parse_size(v)
    elseif k == "obs" then
        opts.obs = parse_size(v)
    elseif k == "cbs" then
        opts.cbs = parse_size(v)
    elseif k == "status" then
        opts.status = v
    elseif k == "conv" then
        opts.conv = parse_list(v)
    elseif k == "iflag" then
        opts.iflag = parse_list(v)
    elseif k == "oflag" then
        opts.oflag = parse_list(v)

    elseif k == "conv" then
        for c in v:gmatch("[^,]+") do
            opts.conv[c] = true
        end

    elseif k == "iflag" then
        for c in v:gmatch("[^,]+") do
            opts.iflag[c] = true
        end

    elseif k == "oflag" then
        for c in v:gmatch("[^,]+") do
            opts.oflag[c] = true
        end
    elseif k == "count" then
        opts.count = tonumber(v)
    elseif k == "skip" then
        opts.skip = tonumber(v)
    elseif k == "seek" or k == "oseek" then
        opts.seek = tonumber(v)

    elseif k == "iseek" then
        opts.skip = tonumber(v)
    elseif arg == "--version" then
        print(VERSION)
        os.exit(0)
    elseif arg == "--help" then
        print([[
Usage: dd [OPERAND]...
Copy a file according to operands.

  bs=BYTES        read/write BYTES bytes at a time
  cbs=BYTES       convert BYTES bytes at a time
  conv=CONVS      conversion options
  count=N         copy only N input blocks
  ibs=BYTES       read BYTES bytes at a time
  if=FILE         read from FILE
  iflag=FLAGS     input flags
  obs=BYTES       write BYTES bytes at a time
  of=FILE         write to FILE
  oflag=FLAGS     output flags
  seek=N          skip N output blocks
  skip=N          skip N input blocks
  status=LEVEL    output status level

Options:
      --help       display this help and exit
      --version    output version information and exit
]])
        os.exit(0)
    end
end

local input
if opts.input == "-" then
    input = io.stdin
else
    input = assert(io.open(opts.input, "rb"))
end

local output
if opts.output == "-" then
    output = io.stdout
else
    output = assert(io.open(opts.output, "wb"))
end

if opts.skip > 0 then
    input:seek("set", opts.skip * opts.ibs)
end

if opts.seek > 0 then
    output:seek("set", opts.seek * opts.obs)
end

local full_in = 0
local partial_in = 0
local full_out = 0
local partial_out = 0
local bytes = 0
local start_time = os.clock()

while true do
    if opts.count and (full_in + partial_in) >= opts.count then
        break
    end

    local data = input:read(opts.ibs)

    if not data then
        break
    end

    if opts.conv.swab then
        local t = {}
        for i = 1, #data, 2 do
            t[#t+1] = data:sub(i+1,i)
            t[#t+1] = data:sub(i,i)
        end
        data = table.concat(t)
    end

    if opts.conv.ucase then
        data = data:upper()
    end

    if opts.conv.lcase then
        data = data:lower()
    end

    output:write(data)

    if #data == opts.ibs then
        full_in = full_in + 1
        full_out = full_out + 1
    else
        partial_in = partial_in + 1
        partial_out = partial_out + 1
    end

    bytes = bytes + #data
end

if input ~= io.stdin then input:close() end
if output ~= io.stdout then output:close() end

local elapsed = os.clock() - start_time

if opts.status ~= "none" and opts.status ~= "noxfer" then
    io.stderr:write(
        string.format(
            "%d+%d records in\n%d+%d records out\n%d bytes copied, %.6f s\n",
            full_in,
            partial_in,
            full_out,
            partial_out,
            bytes,
            elapsed
        )
    )
elseif opts.status ~= "none" then
    io.stderr:write(
        string.format(
            "%d+%d records in\n%d+%d records out\n",
            full_in,
            partial_in,
            full_out,
            partial_out
        )
    )
end
