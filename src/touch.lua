local ffi = require("ffi")
local bit = require("bit")

local VERSION = "luajit-coreutils touch 0.1"

ffi.cdef[[
typedef long time_t;

struct timespec {
    time_t tv_sec;
    long tv_nsec;
};

int open(const char *pathname, int flags, ...);
int close(int fd);
int chmod(const char *pathname, unsigned int mode);

int utimensat(
    int dirfd,
    const char *pathname,
    const struct timespec times[2],
    int flags
);
]]

local O_WRONLY = 1
local O_CREAT = 64

local MODE = tonumber("644", 8)
local AT_FDCWD = -100

local create = true
local only_access = false
local only_modify = false
local reference = nil
local timestamp = nil
local ref_atime = nil
local ref_mtime = nil
local reference = nil
local files = {}


local function help()
    print([[
Usage: touch [OPTION]... FILE...

Update file timestamps.

  -a
         change only access time

  -m
         change only modification time

  -c, --no-create
         do not create files

  -r, --reference FILE
         use this file timestamps

  -t TIME
         use specified time

      --help
         display help

      --version
         output version information
]])
end


local function exists(path)
    local f = io.open(path, "rb")

    if f then
        f:close()
        return true
    end

    return false
end


local function create_file(path)

    local fd = ffi.C.open(
        path,
        bit.bor(O_WRONLY, O_CREAT),
        MODE
    )

    if fd < 0 then
        return false
    end

    ffi.C.close(fd)
    ffi.C.chmod(path, MODE)

    return true
end


local function parse_time(str)

    if str == "now" or str == "today" then
        return os.time()
    end

    local y,m,d,h,mi,se =
        str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)[ T](%d%d):(%d%d):(%d%d)$")

    if y then
        return os.time({
            year=tonumber(y),
            month=tonumber(m),
            day=tonumber(d),
            hour=tonumber(h),
            min=tonumber(mi),
            sec=tonumber(se)
        })
    end

    local date, sec = str:match("^(%d+)%.?(%d*)$")

    if not date then
        return nil
    end

    sec = tonumber(sec) or 0

    if #date ~= 12 then
        return nil
    end

    return os.time({
        year = tonumber(date:sub(1,4)),
        month = tonumber(date:sub(5,6)),
        day = tonumber(date:sub(7,8)),
        hour = tonumber(date:sub(9,10)),
        min = tonumber(date:sub(11,12)),
        sec = sec
    })
end



local function read_reference(path)

    local f = io.popen(
        "stat -c '%X %Y' " .. string.format("%q", path)
    )

    if not f then
        return false
    end

    local line = f:read("*l")
    f:close()

    if not line then
        return false
    end

    ref_atime, ref_mtime = line:match("(%d+) (%d+)")

    if ref_atime then
        ref_atime = tonumber(ref_atime)
        ref_mtime = tonumber(ref_mtime)
        return true
    end

    return false
end

local function update_time(path)

    local ts = ffi.new("struct timespec[2]")

    local t = timestamp or os.time()


    if only_access then
        ts[0].tv_sec = t
        ts[0].tv_nsec = 0

        ts[1].tv_sec = 0
        ts[1].tv_nsec = 1073741823

    elseif only_modify then
        ts[0].tv_sec = 0
        ts[0].tv_nsec = 1073741823

        ts[1].tv_sec = t
        ts[1].tv_nsec = 0

    elseif ref_atime and ref_mtime then
        ts[0].tv_sec = ref_atime
        ts[0].tv_nsec = 0

        ts[1].tv_sec = ref_mtime
        ts[1].tv_nsec = 0

    else
        ts[0].tv_sec = t
        ts[0].tv_nsec = 0

        ts[1].tv_sec = t
        ts[1].tv_nsec = 0
    end

    local ret = ffi.C.utimensat(
        AT_FDCWD,
        path,
        ts,
        0
    )

    return ret == 0
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

    elseif a == "-a" then
        only_access = true
        only_modify = false

    elseif a == "-m" then
        only_modify = true
        only_access = false

    elseif a == "-c" or a == "--no-create" then
        create = false

    elseif a == "-r" or a == "--reference" then
        i = i + 1
        reference = arg[i]

    elseif a:match("^%-%-reference=") then
        reference = a:match("=(.*)")

    elseif a == "-t" then
        i = i + 1
        timestamp = parse_time(arg[i])

    elseif a == "-d" or a == "--date" then
        i = i + 1
        timestamp = parse_time(arg[i])

    elseif a:match("^%-%-date=") then
        timestamp = parse_time(a:match("=(.*)"))

    else
        files[#files+1] = a
    end

    i = i + 1
end


if reference then
    if not read_reference(reference) then
        io.stderr:write(
            "touch: cannot stat '",
            reference,
            "'\n"
        )
        os.exit(1)
    end
end


if #files == 0 then
    help()
    os.exit(1)
end


for _, file in ipairs(files) do

    local ok = exists(file)

    if not ok then

        if not create then
            goto continue
        end

        if not create_file(file) then
            io.stderr:write(
                "touch: cannot create '",
                file,
                "'\n"
            )
            os.exit(1)
        end
    end

    update_time(file)

    ::continue::
end
