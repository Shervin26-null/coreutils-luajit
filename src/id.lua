local ffi = require("ffi")

local VERSION = "luajit-coreutils id 0.1"

ffi.cdef[[
typedef unsigned int uid_t;
typedef unsigned int gid_t;

uid_t getuid(void);
uid_t geteuid(void);
gid_t getgid(void);
gid_t getegid(void);

int getgroups(int size, gid_t list[]);
]]

local C = ffi.C

pcall(function()
ffi.cdef[[
int getcon(char **context);
void free(void *);
]]
end)

local function selinux_context()
    local ok, ctx = pcall(function()
        local p = ffi.new("char *[1]")
        if C.getcon(p) == 0 then
            local s = ffi.string(p[0])
            C.free(p[0])
            return s
        end
    end)

    if ok then return ctx end
    return nil
end

ffi.cdef[[
typedef struct {
    char *pw_name;
} passwd;

typedef struct {
    char *gr_name;
} group;

passwd *getpwuid(uid_t uid);
group *getgrgid(gid_t gid);
]]

local function uid_name(uid)
    local p = C.getpwuid(uid)
    if p == nil then return tostring(uid) end
    return ffi.string(p.pw_name)
end

local function gid_name(gid)
    local g = C.getgrgid(gid)
    if g == nil then return tostring(gid) end
    return ffi.string(g.gr_name)
end

local user_only = false
local group_only = false
local groups_only = false
local name = false
local real = false
local zero = false

for _, a in ipairs({...}) do
    if a == "--help" then
        print([[
Usage: id [OPTION]... [USER]...

  -u, --user       print user ID
  -g, --group      print group ID
  -G, --groups     print all groups
  -n, --name       print names instead of numbers
  -r, --real       real IDs
      --version
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-u" then
        user_only = true
    elseif a == "-g" then
        group_only = true
    elseif a == "-G" then
        groups_only = true
    elseif a == "-n" then
        name = true
    elseif a == "-r" then
        real = true
    elseif a == "-z" then
        zero = true
    end
end

local sep = zero and "\0" or " "

local uid = real and C.getuid() or C.geteuid()
local gid = real and C.getgid() or C.getegid()

if user_only then
    io.write(tonumber(uid), "\n")
    return
end

if group_only then
    io.write(tonumber(gid), "\n")
    return
end

if groups_only then
    local n = C.getgroups(0, nil)
    local groups = ffi.new("gid_t[?]", n)
    C.getgroups(n, groups)

    io.write(tonumber(gid))

    for i = 0, n-1 do
        io.write(sep, tonumber(groups[i]))
    end

    io.write("\n")
    return
end

local uname = uid_name(uid)
local gname = gid_name(gid)

local n = C.getgroups(0, nil)
local groups = ffi.new("gid_t[?]", n)
C.getgroups(n, groups)

io.write(string.format(
    "uid=%d(%s) gid=%d(%s)",
    tonumber(uid),
    uname,
    tonumber(gid),
    gname
))

io.write(" groups=")

io.write(string.format(
    "%d(%s)",
    tonumber(gid),
    gid_name(gid)
))

for i = 0, n-1 do
    io.write(",")
    io.write(string.format(
        "%d(%s)",
        tonumber(groups[i]),
        gid_name(groups[i])
    ))
end

io.write("\n")
