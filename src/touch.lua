#!/usr/bin/env luajit

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
typedef long time_t;

typedef struct {
    time_t tv_sec;
    long tv_usec;
} timeval;

int open(const char *pathname, int flags, unsigned int mode);
int close(int fd);
int utimes(const char *filename, const timeval times[2]);
int stat(const char *path, void *buf);
int access(const char *pathname, int mode);
char *strerror(int errnum);
]]

local C = ffi.C

local VERSION = "luajit-coreutils touch 0.1"

local O_WRONLY = 1
local O_CREAT  = 64
local O_APPEND = 1024

local created = true
local no_create = false
local access_time = true
local modify_time = true

local files = {}

local function die(msg)
    io.stderr:write("touch: " .. msg .. "\n")
    os.exit(1)
end

local function exists(path)
    local buf = ffi.new("char[512]")
    return C.stat(path, buf) == 0
end

local function create_file(path)
    local fd = C.open(
        path,
        bit.bor(O_WRONLY, O_CREAT, O_APPEND),
        420
    )

    if fd < 0 then
        return false
    end

    C.close(fd)
    return true
end

local function update_time(path)
    local now = os.time()

    local tv = ffi.new("timeval[2]")

    tv[0].tv_sec = now
    tv[0].tv_usec = 0

    tv[1].tv_sec = now
    tv[1].tv_usec = 0

    if C.utimes(path, tv) ~= 0 then
        return false
    end

    return true
end


local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        print([[
Usage: touch [OPTION]... FILE...

Update the access and modification times of each FILE.

  -a            change only access time
  -m            change only modification time
  -c            do not create any files
      --no-create  do not create any files
      --help     display this help and exit
      --version  output version information and exit
]])

    elseif a == "--version" then
        print(VERSION)

    elseif a == "-a" then
        modify_time = false

    elseif a == "-m" then
        access_time = false

    elseif a == "-c" or a == "--no-create" then
        no_create = true

    elseif a == "--" then
        for j = i + 1, #arg do
            files[#files+1] = arg[j]
        end
        break

    elseif a:sub(1,1) == "-" then
        die("invalid option '" .. a .. "'")

    else
        files[#files+1] = a
    end

    i = i + 1
end


if #files == 0 then
    die("missing file operand")
end


for _, file in ipairs(files) do

    if not exists(file) then
        if not no_create then
            if not create_file(file) then
                die("cannot touch '" .. file .. "': " ..
                    ffi.string(C.strerror(ffi.errno())))
            end
        else
            goto continue
        end
    end


    if not update_time(file) then
        die("cannot touch '" .. file .. "': " ..
            ffi.string(C.strerror(ffi.errno())))
    end

    ::continue::
end


-- GNU compatibility extensions

local function parse_time(value)
    local t = os.time()

    if value == "now" then
        return t
    end

    local y,m,d,h,min,s =
        value:match("^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):?(%d*)")

    if y then
        return os.time({
            year=tonumber(y),
            month=tonumber(m),
            day=tonumber(d),
            hour=tonumber(h),
            min=tonumber(min),
            sec=tonumber(s ~= "" and s or "0")
        })
    end

    return nil
end


local reference = nil
local no_create = false
local access_time = nil
local modify_time = nil


local old_args = arg
arg = {}

local i = 1
while i <= #old_args do
    local a = old_args[i]

    if a == "-a" then
        access_time = true

    elseif a == "-m" then
        modify_time = true

    elseif a == "-c" or a == "--no-create" then
        no_create = true

    elseif a == "-r" or a == "--reference" then
        i = i + 1
        reference = old_args[i]

    elseif a == "-d" or a == "--date" then
        i = i + 1
        local t = parse_time(old_args[i])
        if not t then
            io.stderr:write("touch: invalid date format\n")
            os.exit(1)
        end

    else
        arg[#arg+1] = a
    end

    i = i + 1
end
