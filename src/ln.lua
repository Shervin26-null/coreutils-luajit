local ffi = require("ffi")

ffi.cdef[[
int link(const char *oldpath, const char *newpath);
int symlink(const char *target, const char *linkpath);
int unlink(const char *pathname);
char *strerror(int errnum);
]]

local C = ffi.C

local VERSION = "luajit-coreutils ln 0.1"

local opts = {
    symbolic = false,
    force = false,
    verbose = false,
}

local files = {}

local function help()
print([[
Usage: ln [OPTION]... TARGET LINK_NAME

Create hard or symbolic links.

  -f, --force
         remove existing destination files
  -s, --symbolic
         make symbolic links
  -v, --verbose
         print name of each linked file

      --help
         display this help and exit
      --version
         output version information and exit
]])
end


for i = 1, #arg do

    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-s" or a == "--symbolic" then
        opts.symbolic = true

    elseif a == "-f" or a == "--force" then
        opts.force = true

    elseif a == "-v" or a == "--verbose" then
        opts.verbose = true

    else
        files[#files+1] = a
    end
end


if #files < 2 then
    io.stderr:write("ln: missing operand\n")
    os.exit(1)
end


local target = files[1]
local dest = files[2]


if opts.force then
    C.unlink(dest)
end


local ret

if opts.symbolic then
    ret = C.symlink(target, dest)
else
    ret = C.link(target, dest)
end


if ret ~= 0 then
    io.stderr:write(
        "ln: failed to create link '",
        dest,
        "'\n"
    )
    os.exit(1)
end


if opts.verbose then
    print(dest .. " -> " .. target)
end
