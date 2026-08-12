local ffi = require("ffi")

ffi.cdef[[
ssize_t readlink(const char *pathname, char *buf, size_t bufsiz);
char *realpath(const char *path, char *resolved_path);
]]

local C = ffi.C

local VERSION = "luajit-coreutils readlink 0.1"

local opts = {
    canonical = false,
    newline = true,
    zero = false,
    quiet = false,
}

local files = {}

local function help()
print([[
Usage: readlink [OPTION]... FILE...

Print value of a symbolic link or canonical file name.

  -f, --canonicalize
         canonicalize path
  -e, --canonicalize-existing
         require all components to exist
  -m, --canonicalize-missing
         allow missing components
  -n, --no-newline
         do not output newline
  -z, --zero
         end output with NUL

  -q, --quiet
         suppress errors

      --help
         display this help
      --version
         output version information
]])
end


for _,a in ipairs(arg) do

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-f" or a == "--canonicalize"
        or a == "-e"
        or a == "--canonicalize-existing"
        or a == "-m"
        or a == "--canonicalize-missing" then

        opts.canonical = true

    elseif a == "-n" or a == "--no-newline" then
        opts.newline = false

    elseif a == "-z" or a == "--zero" then
        opts.zero = true

    elseif a == "-q" or a == "--quiet"
        or a == "-s" or a == "--silent" then

        opts.quiet = true

    else
        files[#files+1] = a
    end
end


if #files == 0 then
    io.stderr:write("readlink: missing operand\n")
    os.exit(1)
end


local function output(s)

    if opts.zero then
        io.write(s, "\0")
    elseif opts.newline then
        print(s)
    else
        io.write(s)
    end

end


local function do_readlink(path)

    if opts.canonical then

        local buf = ffi.new("char[4096]")

        local result = C.realpath(path, buf)

        if result == nil then

            if not opts.quiet then
                io.stderr:write(
                    "readlink: cannot canonicalize '",
                    path,
                    "'\n"
                )
            end

            return false
        end

        output(ffi.string(buf))
        return true
    end


    local buf = ffi.new("char[4096]")

    local len = C.readlink(
        path,
        buf,
        4095
    )


    if len < 0 then

        if not opts.quiet then
            io.stderr:write(
                "readlink: '",
                path,
                "' is not a symbolic link\n"
            )
        end

        return false
    end


    buf[len] = 0

    output(ffi.string(buf))

    return true
end



local failed = false

for _,file in ipairs(files) do

    if not do_readlink(file) then
        failed = true
    end

end


if failed then
    os.exit(1)
end
