local ffi = require("ffi")

ffi.cdef[[
typedef long ssize_t;

int open(const char *path, int flags, ...);
unsigned int sleep(unsigned int seconds);
void (*signal(int signum, void (*handler)(int)))(int);
int close(int fd);
ssize_t read(int fd, void *buf, unsigned long count);
]]

local O_RDONLY = 0

local VERSION = "luajit-coreutils tail 0.1"

local opts = {
    follow = false,
    lines = 10,
    bytes = nil,
    quiet = false,
    verbose = false,
}

local files = {}

local function usage()
    print([[
Usage: tail [OPTION]... [FILE]...

Print the last part of files.

  -c, --bytes=NUM       output the last NUM bytes
  -f, --follow          output appended data as file grows
  -n, --lines=NUM       output the last NUM lines
  -q, --quiet           never output headers
  -v, --verbose         always output headers
      --help            display this help
      --version         output version information
]])
end

local function parse_num(s)
    local n = tonumber(s)
    if not n then
        io.stderr:write("tail: invalid number: ", s, "\n")
        os.exit(1)
    end
    return n
end

local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        usage()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-f" or a == "--follow" then
        opts.follow = true

    elseif a == "-q" or a == "--quiet" or a == "--silent" then
        opts.quiet = true

    elseif a == "-v" or a == "--verbose" then
        opts.verbose = true

    elseif a == "-n" then
        i = i + 1
        opts.lines = parse_num(arg[i])

    elseif a:match("^%-n%d+$") then
        opts.lines = parse_num(a:sub(3))

    elseif a:match("^%-%-lines=") then
        opts.lines = parse_num(a:match("=(.*)"))

    elseif a == "-c" then
        i = i + 1
        opts.bytes = parse_num(arg[i])

    elseif a:match("^%-c%d+$") then
        opts.bytes = parse_num(a:sub(3))

    elseif a:match("^%-%-bytes=") then
        opts.bytes = parse_num(a:match("=(.*)"))

    else
        files[#files + 1] = a
    end

    i = i + 1
end

if #files == 0 then
    files[1] = "-"
end

local function read_file(name)
    local data = {}

    if name == "-" then
        local chunk
        while true do
            chunk = io.read(4096)
            if not chunk then
                break
            end
            data[#data + 1] = chunk
        end

        return table.concat(data)
    end

    local fd = ffi.C.open(name, O_RDONLY)

    if fd < 0 then
        io.stderr:write("tail: cannot open '", name, "'\n")
        return nil
    end

    local buf = ffi.new("char[4096]")

    while true do
        local n = ffi.C.read(fd, buf, 4096)

        if n <= 0 then
            break
        end

        data[#data + 1] = ffi.string(buf, n)
    end

    ffi.C.close(fd)

    return table.concat(data)
end


local function tail_data(data)
    if opts.bytes then
        local start = #data - opts.bytes + 1

        if start < 1 then
            start = 1
        end

        return data:sub(start)
    end

    local count = 0
    local start = 1

    for i = #data, 1, -1 do
        if data:sub(i, i) == "\n" then
            count = count + 1

            if count > opts.lines then
                start = i + 1
                break
            end
        end
    end

    return data:sub(start)
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

        io.write(tail_data(data))
    end
end



if opts.follow then
    local file = files[#files]

    if file == "-" then
        os.exit(0)
    end

    local last = #(read_file(file) or "")

    while true do
        local data = read_file(file)

        if data and #data > last then
            io.write(data:sub(last + 1))
            io.flush()
            last = #data
        end

        pcall(ffi.C.sleep, 1)
    end
end
