local ffi = require("ffi")

ffi.cdef[[
typedef long ssize_t;

int open(const char *path, int flags, ...);
int close(int fd);
ssize_t read(int fd, void *buf, unsigned long count);
]]

local O_RDONLY = 0

local VERSION = "luajit-coreutils wc 0.1"

local opts = {
    lines = false,
    words = false,
    chars = false,
    bytes = false,
    maxline = false,
    debug = false,
    total = "auto",
    files0 = nil,
}

local files = {}

local function help()
print([[
Usage: wc [OPTION]... [FILE]...
  or:  wc [OPTION]... --files0-from=F

Print newline, word, and byte counts for each FILE.

With no FILE, or when FILE is -, read standard input.

The options below select which counts are printed:
newline, word, character, byte, maximum line length.

  -c, --bytes
         print the byte counts
  -m, --chars
         print the character counts
  -l, --lines
         print the newline counts
      --debug
         indicate line count acceleration
      --files0-from=F
         read NUL-terminated file names from F
  -L, --max-line-length
         print the maximum display width
  -w, --words
         print the word counts
      --total=WHEN
         WHEN: auto, always, only, never
      --help
         display this help and exit
      --version
         output version information
]])
end


local function add_file(name)
    files[#files + 1] = name
end


for _, a in ipairs(arg) do

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-l" or a == "--lines" then
        opts.lines = true

    elseif a == "-w" or a == "--words" then
        opts.words = true

    elseif a == "-c" or a == "--bytes" then
        opts.bytes = true

    elseif a == "-m" or a == "--chars" then
        opts.chars = true

    elseif a == "-L" or a == "--max-line-length" then
        opts.maxline = true

    elseif a == "--debug" then
        opts.debug = true

    elseif a:match("^%-%-total=") then
        opts.total = a:match("=(.*)")

    elseif a:match("^%-%-files0%-from=") then
        opts.files0 = a:match("=(.*)")

    else
        add_file(a)
    end
end


if not opts.lines
and not opts.words
and not opts.chars
and not opts.bytes
and not opts.maxline then
    opts.lines = true
    opts.words = true
    opts.bytes = true
end


if opts.files0 then
    local f = io.open(opts.files0, "rb")

    if f then
        for name in f:read("*a"):gmatch("([^%z]+)") do
            add_file(name)
        end
        f:close()
    end
end


if #files == 0 then
    files[1] = "-"
end

local function read_file(name)
    local chunks = {}

    if name == "-" then
        while true do
            local s = io.read(4096)
            if not s then break end
            chunks[#chunks + 1] = s
        end

        return table.concat(chunks)
    end

    local fd = ffi.C.open(name, O_RDONLY)

    if fd < 0 then
        io.stderr:write("wc: cannot open '", name, "'\n")
        return nil
    end

    local buf = ffi.new("char[8192]")

    while true do
        local n = ffi.C.read(fd, buf, 8192)

        if n <= 0 then
            break
        end

        chunks[#chunks + 1] = ffi.string(buf, n)
    end

    ffi.C.close(fd)

    return table.concat(chunks)
end


local function count_data(data)
    local result = {
        lines = 0,
        words = 0,
        chars = 0,
        bytes = #data,
        maxline = 0
    }

    local current = 0
    local inword = false

    for i = 1, #data do
        local c = data:sub(i, i)

        local b = string.byte(c)

        if b < 0x80 or (b >= 0xC0 and b <= 0xFD) then
            result.chars = result.chars + 1
        end

        if c == "\n" then
            result.lines = result.lines + 1

            if current > result.maxline then
                result.maxline = current
            end

            current = 0

        else
            current = current + 1
        end

        if c:match("%s") then
            inword = false
        elseif not inword then
            result.words = result.words + 1
            inword = true
        end
    end

    if current > result.maxline then
        result.maxline = current
    end

    return result
end


local function output(c, name)
    local out = {}

    if opts.lines then
        out[#out + 1] = c.lines
    end

    if opts.words then
        out[#out + 1] = c.words
    end

    if opts.chars then
        out[#out + 1] = c.chars
    end

    if opts.bytes then
        out[#out + 1] = c.bytes
    end

    if opts.maxline then
        out[#out + 1] = c.maxline
    end

    print(table.concat(out, "\t") .. "\t" .. name)
end


local total = {
    lines = 0,
    words = 0,
    chars = 0,
    bytes = 0,
    maxline = 0
}

local count = 0

for _, file in ipairs(files) do
    local data = read_file(file)

    if data then
        local c = count_data(data)

        total.lines = total.lines + c.lines
        total.words = total.words + c.words
        total.chars = total.chars + c.chars
        total.bytes = total.bytes + c.bytes

        if c.maxline > total.maxline then
            total.maxline = c.maxline
        end

        output(c, file)

        count = count + 1
    end
end


if count > 1 and opts.total ~= "never" then
    output(total, "total")
elseif opts.total == "always" then
    output(total, "total")
end
