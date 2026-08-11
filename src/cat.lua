#!/usr/bin/env luajit

local ffi = require("ffi")

ffi.cdef[[
int open(const char *pathname, int flags, ...);
int close(int fd);
long read(int fd, void *buf, unsigned long count);
long write(int fd, const void *buf, unsigned long count);
char *strerror(int errnum);
]]

local C = ffi.C

local VERSION = "luajit-coreutils cat 0.1"

local O_RDONLY = 0

local number = false
local number_nonblank = false
local squeeze = false

local show_nonprinting = false
local show_ends = false
local show_tabs = false

local files = {}

local function die(msg)
    io.stderr:write("cat: ", msg, "\n")
    os.exit(1)
end

local function help()
    io.write([[
Usage: cat [OPTION]... [FILE]...

  -n              number all output lines
  -b              number nonempty output lines
  -s              squeeze repeated blank lines
  -v              show nonprinting characters
  -E              print $ at end of each line
  -T              display TAB characters as ^I
  -A              equivalent to -vET
      --help      display this help and exit
      --version   output version information and exit
]])
end


local function transform(data)
    local out = {}
    local line = 1
    local start = true
    local blank = 0

    for i = 1, #data do
        local ch = data:sub(i,i)
        local byte = string.byte(ch)

        if start then
            if number then
                out[#out+1] = string.format("%6d\t", line)
                line = line + 1
                start = false

            elseif number_nonblank and ch ~= "\n" then
                out[#out+1] = string.format("%6d\t", line)
                line = line + 1
                start = false
            end
        end

        if ch == "\n" then
            if squeeze then
                blank = blank + 1
                if blank > 1 then
                    start = true
                    goto continue
                end
            end
        else
            blank = 0
        end


        if show_tabs and ch == "\t" then
            ch = "^I"

        elseif show_nonprinting then
            if byte < 32 and ch ~= "\n" and ch ~= "\t" then
                ch = "^" .. string.char(byte + 64)
            elseif byte == 127 then
                ch = "^?"
            end
        end


        if show_ends and ch == "\n" then
            out[#out+1] = "$\n"
        else
            out[#out+1] = ch
        end


        if data:sub(i,i) == "\n" then
            start = true
        end

        ::continue::
    end

    return table.concat(out)
end


local function cat_fd(fd)
    local buf = ffi.new("char[65536]")

    while true do
        local n = C.read(fd, buf, 65536)

        if n <= 0 then
            break
        end

        local data = ffi.string(buf, n)

        if not number and
           not number_nonblank and
           not squeeze and
           not show_nonprinting and
           not show_ends and
           not show_tabs then

            C.write(1, data, n)

        else
            local result = transform(data)
            C.write(1, result, #result)
        end
    end
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

    elseif a == "--" then
        for j = i + 1, #arg do
            files[#files+1] = arg[j]
        end
        break

    elseif a == "-n" then
        number = true

    elseif a == "-b" then
        number_nonblank = true

    elseif a == "-s" then
        squeeze = true

    elseif a == "-v" then
        show_nonprinting = true

    elseif a == "-E" then
        show_ends = true

    elseif a == "-T" then
        show_tabs = true

    elseif a == "-A" then
        show_nonprinting = true
        show_ends = true
        show_tabs = true

    elseif a:sub(1,1) == "-" and #a > 1 then
        for j = 2, #a do
            local c = a:sub(j,j)

            if c == "n" then
                number = true
            elseif c == "b" then
                number_nonblank = true
            elseif c == "s" then
                squeeze = true
            elseif c == "v" then
                show_nonprinting = true
            elseif c == "E" then
                show_ends = true
            elseif c == "T" then
                show_tabs = true
            elseif c == "A" then
                show_nonprinting = true
                show_ends = true
                show_tabs = true
            else
                die("invalid option -- '" .. c .. "'")
            end
        end

    else
        files[#files+1] = a
    end

    i = i + 1
end


if #files == 0 then
    cat_fd(0)
else
    for _, file in ipairs(files) do
        local fd

        if file == "-" then
            fd = 0
        else
            fd = C.open(file, O_RDONLY)

            if fd < 0 then
                die(file .. ": " .. ffi.string(C.strerror(ffi.errno())))
            end
        end

        cat_fd(fd)

        if fd ~= 0 then
            C.close(fd)
        end
    end
end
