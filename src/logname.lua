local ffi = require("ffi")

local VERSION = "logname (coreutils-luajit) 0.1"

ffi.cdef[[
typedef unsigned int uid_t;

struct passwd {
    char *pw_name;
    char *pw_passwd;
    uid_t pw_uid;
    unsigned int pw_gid;
    char *pw_gecos;
    char *pw_dir;
    char *pw_shell;
};

struct passwd *getpwuid(uid_t uid);
uid_t getuid(void);
]]

local C = ffi.C

for _, a in ipairs(arg) do
    if a == "--help" then
        print([[
Usage: logname [OPTION]
Print the user's login name.

      --help
         display this help and exit
      --version
         output version information and exit
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    else
        io.stderr:write("logname: unrecognized option '", a, "'\n")
        os.exit(1)
    end
end

local pw = C.getpwuid(C.getuid())

if pw == nil then
    io.stderr:write("logname: no login name\n")
    os.exit(1)
end

print(ffi.string(pw.pw_name))
