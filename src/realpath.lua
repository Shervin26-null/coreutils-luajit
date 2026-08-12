local ffi = require("ffi")

ffi.cdef[[
char *realpath(const char *path, char *resolved_path);
]]

local C = ffi.C

local VERSION = "luajit-coreutils realpath 0.1"

local opts = {
    zero = false,
    quiet = false,
    strip = false,
}

local files = {}

local function help()
print([[
Usage: realpath [OPTION]... FILE...

Print the resolved absolute file name.

  -E, --canonicalize
         all but last component must exist
  -e, --canonicalize-existing
         all components must exist
  -m, --canonicalize-missing
         allow missing components
  -L, --logical
         resolve .. before symlinks
  -P, --physical
         resolve symlinks as encountered
  -q, --quiet
         suppress errors
  -s, --strip, --no-symlinks
         don't expand symlinks
  -z, --zero
         end output with NUL

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

    elseif a == "-q" or a == "--quiet" then
        opts.quiet = true

    elseif a == "-z" or a == "--zero" then
        opts.zero = true

    elseif a == "-s"
        or a == "--strip"
        or a == "--no-symlinks" then

        opts.strip = true

    elseif a == "-E"
        or a == "--canonicalize"
        or a == "-e"
        or a == "--canonicalize-existing"
        or a == "-m"
        or a == "--canonicalize-missing"
        or a == "-L"
        or a == "--logical"
        or a == "-P"
        or a == "--physical" then

        -- accepted, default behavior is physical

    else
        files[#files+1] = a
    end
end


if #files == 0 then
    io.stderr:write("realpath: missing operand\n")
    os.exit(1)
end


local function output(s)

    if opts.zero then
        io.write(s, "\0")
    else
        print(s)
    end

end


local function resolve(path)

    if opts.strip then
        return path
    end

    local buf = ffi.new("char[4096]")

    local result = C.realpath(path, buf)

    if result == nil then

        if not opts.quiet then
            io.stderr:write(
                "realpath: '",
                path,
                "': No such file or directory\n"
            )
        end

        return nil
    end

    return ffi.string(buf)
end



local failed = false


for _,file in ipairs(files) do

    local path = resolve(file)

    if path then
        output(path)
    else
        failed = true
    end

end


if failed then
    os.exit(1)
end
