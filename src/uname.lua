local ffi = require("ffi")

ffi.cdef[[
typedef unsigned long size_t;

int uname(void *buf);

char *getenv(const char *name);
]]

local VERSION = "luajit-coreutils uname 0.1"

local SYS_NMLN = 65

local utsname = ffi.typeof([[
struct {
    char sysname[65];
    char nodename[65];
    char release[65];
    char version[65];
    char machine[65];
    char domainname[65];
}
]])

local function get_uname()
    local buf = ffi.new(utsname)

    if ffi.C.uname(buf) ~= 0 then
        io.stderr:write("uname: failed to get system information\n")
        os.exit(1)
    end

    return {
        sysname = ffi.string(buf.sysname),
        nodename = ffi.string(buf.nodename),
        release = ffi.string(buf.release),
        version = ffi.string(buf.version),
        machine = ffi.string(buf.machine),
        domainname = ffi.string(buf.domainname),
    }
end

local u = get_uname()

local opts = {
    s = false,
    n = false,
    r = false,
    v = false,
    m = false,
    o = false,
}

local any = false

for _, a in ipairs(arg) do
    if a == "--help" then
        print([[
Usage: uname [OPTION]...

Print system information.

  -a, --all        print all information
  -s               kernel name
  -n               hostname
  -r               kernel release
  -v               kernel version
  -m               machine hardware name
  -o               operating system
      --version    output version
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-a" or a == "--all" then
        opts.s = true
        opts.n = true
        opts.r = true
        opts.v = true
        opts.m = true
        opts.o = true
        any = true

    elseif a:sub(1,1) == "-" then
        for c in a:sub(2):gmatch(".") do
            if opts[c] ~= nil then
                opts[c] = true
                any = true
            end
        end
    end
end

if not any then
    opts.s = true
end

local out = {}

if opts.s then
    out[#out + 1] = u.sysname
end

if opts.n then
    out[#out + 1] = u.nodename
end

if opts.r then
    out[#out + 1] = u.release
end

if opts.v then
    out[#out + 1] = u.version
end

if opts.m then
    out[#out + 1] = u.machine
end

if opts.o then
    out[#out + 1] = "GNU/Linux"
end

print(table.concat(out, " "))
