local ffi = require("ffi")

ffi.cdef[[
typedef unsigned int uid_t;
uid_t getuid(void);
char *getenv(const char *name);
]]

local name = ffi.C.getenv("USER")

if name ~= nil then
    print(ffi.string(name))
    os.exit(0)
end

ffi.cdef[[
struct passwd {
    char *pw_name;
};
struct passwd *getpwuid(uid_t uid);
]]

local pw = ffi.C.getpwuid(ffi.C.getuid())

if pw ~= nil then
    print(ffi.string(pw.pw_name))
    os.exit(0)
end

io.stderr:write("whoami: cannot find username\n")
os.exit(1)
