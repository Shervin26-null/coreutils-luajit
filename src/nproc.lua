local ffi = require("ffi")

local VERSION = "luajit-coreutils nproc 0.1"

ffi.cdef[[
long sysconf(int name);

typedef struct FILE FILE;
FILE *fopen(const char *path, const char *mode);
int fclose(FILE *stream);
]]

-- POSIX constants
local _SC_NPROCESSORS_CONF = 83
local _SC_NPROCESSORS_ONLN = 84


local function get_sysconf(all)
    local id

    if all then
        id = _SC_NPROCESSORS_CONF
    else
        id = _SC_NPROCESSORS_ONLN
    end

    local n = tonumber(ffi.C.sysconf(id))

    if n and n > 0 then
        return n
    end

    return nil
end


local function get_proc_cpuinfo()
    local f = io.open("/proc/cpuinfo", "r")

    if not f then
        return nil
    end

    local count = 0

    for line in f:lines() do
        if line:match("^processor%s*:") then
            count = count + 1
        end
    end

    f:close()

    if count > 0 then
        return count
    end

    return nil
end


local function cpu_count(all)
    local n = get_sysconf(all)

    if n then
        return n
    end

    n = get_proc_cpuinfo()

    if n then
        return n
    end

    return 1
end


local function usage()
    io.write([[
Usage: nproc [OPTION]...

Print the number of processing units available.

      --all
             print installed processors

      --ignore=N
             exclude N processors

      --help
             display this help

      --version
             output version information
]])
end


local all = false
local ignore = 0

local args = {...}

local i = 1

while i <= #args do

    local arg = args[i]

    if arg == "--all" then
        all = true


    elseif arg == "--help" then
        usage()
        os.exit(0)


    elseif arg == "--version" then
        print(VERSION)
        os.exit(0)


    elseif arg:match("^%-%-ignore=") then

        local value = arg:match("^%-%-ignore=(.*)$")

        ignore = tonumber(value)

        if not ignore then
            io.stderr:write(
                "nproc: invalid argument '" ..
                value ..
                "' for '--ignore'\n"
            )
            os.exit(1)
        end


    elseif arg == "--ignore" then

        i = i + 1

        if not args[i] then
            io.stderr:write(
                "nproc: option '--ignore' requires an argument\n"
            )
            os.exit(1)
        end

        ignore = tonumber(args[i])

        if not ignore then
            io.stderr:write(
                "nproc: invalid ignore value\n"
            )
            os.exit(1)
        end


    else
        io.stderr:write(
            "nproc: unrecognized option '" ..
            arg ..
            "'\n"
        )
        os.exit(1)
    end

    i = i + 1
end


local n = cpu_count(all)

n = n - ignore

if n < 1 then
    n = 1
end


print(n)
