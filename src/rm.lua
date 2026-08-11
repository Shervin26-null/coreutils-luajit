#!/usr/bin/env luajit

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
typedef struct DIR DIR;

struct dirent {
    unsigned long ino;
    unsigned long off;
    unsigned short reclen;
    unsigned char type;
    char name[256];
};

int unlink(const char *pathname);
int rmdir(const char *pathname);

DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp);
int closedir(DIR *dirp);

char *strerror(int errnum);
]]

local C = ffi.C

local VERSION = "luajit-coreutils rm 0.1"

local recursive = false
local force = false
local verbose = false

local files = {}

local function error_msg(path)
    io.stderr:write(
        "rm: cannot remove '",
        path,
        "': ",
        ffi.string(C.strerror(ffi.errno())),
        "\n"
    )
end

local function remove_path(path)
    if C.unlink(path) == 0 then
        if verbose then
            io.write("removed '", path, "'\n")
        end
        return true
    end

    if not recursive then
        if not force then
            error_msg(path)
        end
        return false
    end

    local dir = C.opendir(path)

    if dir == nil then
        if not force then
            error_msg(path)
        end
        return false
    end

    while true do
        local ent = C.readdir(dir)

        if ent == nil then
            break
        end

        local name = ffi.string(ent.name)

        if name ~= "." and name ~= ".." then
            remove_path(path .. "/" .. name)
        end
    end

    C.closedir(dir)

    if C.rmdir(path) == 0 then
        if verbose then
            io.write("removed '", path, "'\n")
        end
        return true
    end

    if not force then
        error_msg(path)
    end

    return false
end


local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        print([[
Usage: rm [OPTION]... FILE...
Remove files or directories.

  -f, --force           ignore nonexistent files
  -r, -R, --recursive   remove directories recursively
  -v, --verbose         explain what is being done
      --version         output version information
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "--" then
        for j = i + 1, #arg do
            files[#files+1] = arg[j]
        end
        break

    elseif a:sub(1,2) == "--" then
        if a == "--force" then
            force = true
        elseif a == "--recursive" then
            recursive = true
        elseif a == "--verbose" then
            verbose = true
        else
            io.stderr:write("rm: unrecognized option '", a, "'\n")
            os.exit(1)
        end

    elseif a:sub(1,1) == "-" and #a > 1 then
        for j = 2, #a do
            local c = a:sub(j,j)

            if c == "f" then
                force = true
            elseif c == "r" or c == "R" then
                recursive = true
            elseif c == "v" then
                verbose = true
            else
                io.stderr:write("rm: invalid option '-", c, "'\n")
                os.exit(1)
            end
        end

    else
        files[#files+1] = a
    end

    i = i + 1
end


if #files == 0 then
    io.stderr:write("rm: missing operand\n")
    os.exit(1)
end


for _, file in ipairs(files) do
    remove_path(file)
end
