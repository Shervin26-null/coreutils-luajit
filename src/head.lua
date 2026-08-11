local ffi = require("ffi")

ffi.cdef[[
typedef long ssize_t;

int open(const char *path, int flags, ...);
int close(int fd);
ssize_t read(int fd, void *buf, unsigned long count);
]]

local O_RDONLY = 0

local VERSION = "luajit-coreutils head 0.1"

local opts = {
    lines = 10,
    bytes = nil,
    bytes_mode = false,
    zero = false,
    quiet = false,
    verbose = false,
}

local files = {}

local function help()
print([[
Usage: head [OPTION]... [FILE]...
Print the first 10 lines of each FILE to standard output.
With more than one FILE, precede each with a header giving the file name.

With no FILE, or when FILE is -, read standard input.

Mandatory arguments to long options are mandatory for short options too.
  -c, --bytes=[-]NUM
         print the first NUM bytes of each file
  -n, --lines=[-]NUM
         print the first NUM lines instead of the first 10
  -q, --quiet, --silent
         never print headers giving file names
  -v, --verbose
         always print headers giving file names
  -z, --zero-terminated
         line delimiter is NUL, not newline
      --help
         display this help and exit
      --version
         output version information and exit

NUM may have a multiplier suffix:
b 512, kB 1000, K 1024, MB 1000*1000, M 1024*1024,
GB 1000*1000*1000, G 1024*1024*1024.
]])
end

local function parse_num(s)
    local mult = 1

    if s:sub(-1) == "K" then
        mult = 1024
        s = s:sub(1,-2)
    elseif s:sub(-2) == "kB" then
        mult = 1000
        s = s:sub(1,-3)
    elseif s:sub(-1) == "M" then
        mult = 1024 * 1024
        s = s:sub(1,-2)
    elseif s:sub(-2) == "MB" then
        mult = 1000 * 1000
        s = s:sub(1,-3)
    end

    return tonumber(s) * mult
end

local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-q" or a == "--quiet" or a == "--silent" then
        opts.quiet = true

    elseif a == "-v" or a == "--verbose" then
        opts.verbose = true

    elseif a == "-z" or a == "--zero-terminated" then
        opts.zero = true

    elseif a == "-n" or a == "--lines" then
        i = i + 1
        opts.lines = parse_num(arg[i])

    elseif a:match("^%-n") then
        opts.lines = parse_num(a:sub(3))

    elseif a:match("^%-%-lines=") then
        opts.lines = parse_num(a:match("=(.*)"))

    elseif a == "-c" or a == "--bytes" then
        i = i + 1
        opts.bytes = parse_num(arg[i])
        opts.bytes_mode = true

    elseif a:match("^%-c") then
        opts.bytes = parse_num(a:sub(3))
        opts.bytes_mode = true

    elseif a:match("^%-%-bytes=") then
        opts.bytes = parse_num(a:match("=(.*)"))
        opts.bytes_mode = true

    else
        files[#files+1] = a
    end

    i = i + 1
end

if #files == 0 then
    files[1] = "-"
end

local function read_file(name)
    local chunks = {}

    if name == "-" then
        while true do
            local data = io.read(4096)

            if not data then
                break
            end

            chunks[#chunks + 1] = data
        end

        return table.concat(chunks)
    end

    local fd = ffi.C.open(name, O_RDONLY)

    if fd < 0 then
        io.stderr:write("head: cannot open '", name, "'\n")
        return nil
    end

    local buf = ffi.new("char[4096]")

    while true do
        local n = ffi.C.read(fd, buf, 4096)

        if n <= 0 then
            break
        end

        chunks[#chunks + 1] = ffi.string(buf, n)

        if opts.bytes and #table.concat(chunks) >= opts.bytes then
            break
        end
    end

    ffi.C.close(fd)

    return table.concat(chunks)
end


local function output_head(data)
    if opts.bytes then
        return data:sub(1, opts.bytes)
    end

    local delimiter = "\n"

    if opts.zero then
        delimiter = "\0"
    end

    local count = 0

    for i = 1, #data do
        if data:sub(i, i) == delimiter then
            count = count + 1

            if count == opts.lines then
                return data:sub(1, i)
            end
        end
    end

    return data
end


local multiple = #files > 1

for _, file in ipairs(files) do
    local data = read_file(file)

    if data then
        if multiple and not opts.quiet then
            print("==> " .. file .. " <==")
        elseif opts.verbose then
            print("==> " .. file .. " <==")
        end

        io.write(output_head(data))

        if multiple then
            io.write("\n")
        end
    end
end
