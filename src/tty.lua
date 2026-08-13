local ffi = require("ffi")

local VERSION = "luajit-coreutils tty 0.1"

ffi.cdef[[
char *ttyname(int fd);
int isatty(int fd);
]]

local C = ffi.C

local silent = false

for _, a in ipairs({...}) do
    if a == "--help" then
        print([[
Usage: tty [OPTION]...

Print the file name of the terminal connected to standard input.

  -s, --silent, --quiet
         print nothing, only return an exit status
      --help
         display this help and exit
      --version
         output version information and exit
]])
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-s" or a == "--silent" or a == "--quiet" then
        silent = true
    end
end

local name = C.ttyname(0)

if name == nil then
    if not silent then
        print("not a tty")
    end
    os.exit(1)
end

if not silent then
    print(ffi.string(name))
end

os.exit(0)
