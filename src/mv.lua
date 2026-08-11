#!/usr/bin/env luajit

local ffi = require("ffi")
local C = ffi.C

ffi.cdef[[
int rename(const char *oldpath, const char *newpath);
int unlink(const char *pathname);
int stat(const char *pathname, void *statbuf);
int access(const char *pathname, int mode);
int chmod(const char *pathname, unsigned int mode);
]]

local VERSION = "luajit-coreutils mv 0.1"

local verbose = false
local force = false
local interactive = false
local update = false
local no_clobber = false

local function die(msg)
    io.stderr:write("mv: ", msg, "\n")
    os.exit(1)
end

local function exists(path)
    local st = ffi.new("char[512]")
    return C.stat(path, st) == 0
end

local function remove_file(path)
    return C.unlink(path) == 0
end

local function ask(path)
    io.stderr:write("mv: overwrite '", path, "'? ")
    local a = io.read()
    return a and (a == "y" or a == "Y")
end

local args = {}

for _, a in ipairs(arg) do

    if a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "--help" then
        print([[
Usage: mv [OPTION]... SOURCE DEST
Move SOURCE to DEST.

Options:
  -f, --force              do not prompt before overwriting
  -i, --interactive        prompt before overwrite
  -n, --no-clobber         do not overwrite existing file
  -u, --update             move only when SOURCE is newer
  -v, --verbose            explain what is being done
      --help               display this help
      --version            output version information
]])
        os.exit(0)

    elseif a == "--force" or a == "-f" then
        force = true

    elseif a == "--interactive" or a == "-i" then
        interactive = true

    elseif a == "--no-clobber" or a == "-n" then
        no_clobber = true

    elseif a == "--update" or a == "-u" then
        update = true

    elseif a == "--verbose" or a == "-v" then
        verbose = true

    elseif a:sub(1,2) == "--" then
        die("unrecognized option '" .. a .. "'")

    elseif a:sub(1,1) == "-" and #a > 1 then
        for i = 2, #a do
            local c = a:sub(i,i)

            if c == "f" then
                force = true
            elseif c == "i" then
                interactive = true
            elseif c == "n" then
                no_clobber = true
            elseif c == "u" then
                update = true
            elseif c == "v" then
                verbose = true
            else
                die("invalid option -- '" .. c .. "'")
            end
        end

    else
        args[#args+1] = a
    end
end

if #args < 2 then
    die("missing file operand")
end

local src = args[1]
local dst = args[2]

if exists(dst) then

    if no_clobber then
        os.exit(0)
    end

    if interactive and not force then
        if not ask(dst) then
            os.exit(0)
        end
    end

    if force then
        remove_file(dst)
    end
end

if C.rename(src, dst) ~= 0 then
    die("cannot move '" .. src .. "' to '" .. dst .. "'")
end

if verbose then
    io.write("renamed '", src, "' -> '", dst, "'\n")
end
