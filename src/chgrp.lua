local ffi = require("ffi")

local VERSION = "chgrp (coreutils-luajit) 0.1"

ffi.cdef[[
typedef unsigned int gid_t;

int chown(const char *path, int owner, gid_t group);
int lchown(const char *path, int owner, gid_t group);

struct group {
    char *gr_name;
    char *gr_passwd;
    gid_t gr_gid;
    char **gr_mem;
};

struct group *getgrnam(const char *);
]]

local C = ffi.C

local recursive = false
local no_deref = false
local verbose = false
local changes = false
local quiet = false
local reference = nil
local group = nil
local files = {}

local function parse_gid(name)
    if not name then
        return nil
    end

    local n = tonumber(name)
    if n then
        return n
    end

    local g = C.getgrnam(name)

    if g == nil then
        return nil
    end

    return tonumber(g.gr_gid)
end

local function expand_flags()
    local out = {}

    for _, a in ipairs(arg) do
        if a:sub(1,1) == "-" and not a:match("^%-%-") and #a > 2 then
            for i = 2, #a do
                out[#out+1] = "-" .. a:sub(i,i)
            end
        else
            out[#out+1] = a
        end
    end

    arg = out
end

expand_flags()

local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        print([[
Usage: chgrp [OPTION]... GROUP FILE...

  -c, --changes
  -f, --silent
  -v, --verbose
  -h, --no-dereference
  -R, --recursive
      --reference=RFILE
      --help
      --version
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-R" or a == "--recursive" then
        recursive = true

    elseif a == "-h" or a == "--no-dereference" then
        no_deref = true

    elseif a == "-v" or a == "--verbose" then
        verbose = true

    elseif a == "-c" or a == "--changes" then
        changes = true

    elseif a == "-f" or a == "--silent" or a == "--quiet" then
        quiet = true

    elseif a:match("^%-%-reference=") then
        reference = a:match("^%-%-reference=(.*)$")

    elseif not group then
        group = a

    else
        files[#files+1] = a
    end

    i = i + 1
end


if reference then
    local p = io.popen("stat -c '%g' " .. reference)
    group = p:read("*l")
    p:close()
end


local gid = parse_gid(group)

if not gid then
    if not quiet then
        io.stderr:write("chgrp: invalid group: '", tostring(group), "'\n")
    end
    os.exit(1)
end


if #files == 0 then
    io.stderr:write("chgrp: missing operand\n")
    os.exit(1)
end


local function change(path)
    local r

    if no_deref then
        r = C.lchown(path, -1, gid)
    else
        r = C.chown(path, -1, gid)
    end

    if r ~= 0 then
        if not quiet then
            io.stderr:write("chgrp: changing group of '", path, "' failed\n")
        end
        return false
    end

    if verbose then
        print("changed group of '" .. path .. "'")
    end

    return true
end


local function walk(path)
    change(path)

    if not recursive then
        return
    end

    local p = io.popen("find '" .. path .. "' -mindepth 1 2>/dev/null")

    if p then
        for f in p:lines() do
            change(f)
        end
        p:close()
    end
end


for _, f in ipairs(files) do
    walk(f)
end
