#!/usr/bin/env luajit

local VERSION = "luajit-coreutils install 0.1"

local opts = {
    mode = "755",
    directory = false,
    verbose = false,
    strip = false,
    preserve = false,
    compare = false,
    target = nil,
    no_target = false,
}

local files = {}

local function help()
print([[
Usage: install [OPTION]... [-T] SOURCE DEST
  or:  install [OPTION]... SOURCE... DIRECTORY
  or:  install [OPTION]... -t DIRECTORY SOURCE...
  or:  install [OPTION]... -d DIRECTORY...

Copy files and set attributes.

Options:
  -d, --directory
         create directories
  -D
         create leading destination directories
  -m, --mode=MODE
         set permission mode
  -p, --preserve-timestamps
         preserve timestamps
  -s, --strip
         strip binaries
  -t, --target-directory=DIRECTORY
         copy files into DIRECTORY
  -T, --no-target-directory
         treat DEST as a file
  -v, --verbose
         print created files
      --help
         display this help
      --version
         output version information
]])
end


local function exists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
        return true
    end
    return false
end


local function mkdir_p(path)
    os.execute("mkdir -p " .. string.format("%q", path))
end


local function set_mode(path)
    os.execute(
        "chmod " ..
        opts.mode ..
        " " ..
        string.format("%q", path)
    )
end

local function is_dir(path)
    local f = io.popen("[ -d " .. string.format("%q", path) .. " ] && echo yes")
    if not f then return false end
    local r = f:read("*a")
    f:close()
    return r:match("yes") ~= nil
end


local function copy(src, dst)

    local input = io.open(src, "rb")

    if not input then
        io.stderr:write(
            "install: cannot open '",
            src,
            "'\n"
        )
        return false
    end


    local output = io.open(dst, "wb")

    if not output then
        input:close()

        io.stderr:write(
            "install: cannot create '",
            dst,
            "'\n"
        )
        return false
    end


    while true do
        local data = input:read(1024 * 1024)

        if not data then
            break
        end

        output:write(data)
    end


    input:close()
    output:close()


    set_mode(dst)


    if opts.strip then
        os.execute(
            "strip " ..
            string.format("%q", dst)
        )
    end


    if opts.verbose then
        print(
            "install: '",
            src,
            "' -> '",
            dst,
            "'"
        )
    end

    return true
end


for _,a in ipairs(arg) do

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-d"
        or a == "--directory" then

        opts.directory = true


    elseif a == "-D" then

        opts.create_dirs = true


    elseif a == "-v"
        or a == "--verbose" then

        opts.verbose = true


    elseif a == "-s"
        or a == "--strip" then

        opts.strip = true


    elseif a == "-p"
        or a == "--preserve-timestamps" then

        opts.preserve = true


    elseif a == "-T"
        or a == "--no-target-directory" then

        opts.no_target = true


    elseif a:match("^%-m=") then

        opts.mode = a:match("^%-m=(.*)")


    elseif a == "-m" then
        -- next argument handled below


    elseif a:match("^%-%-mode=") then

        opts.mode = a:match("^%-%-mode=(.*)")


    elseif a:match("^%-t=") then

        opts.target = a:match("^%-t=(.*)")


    elseif a == "-t" then
        -- next argument handled below


    else
        files[#files+1] = a
    end
end


-- second pass for -m MODE and -t DIR
local clean = {}
local i = 1

while i <= #arg do

    if arg[i] == "-m" then
        i = i + 1
        opts.mode = arg[i]

    elseif arg[i] == "-t" then
        i = i + 1
        opts.target = arg[i]

    else
        if not arg[i]:match("^%-") then
            clean[#clean+1] = arg[i]
        end
    end

    i = i + 1
end

files = clean


if opts.directory then

    if #files == 0 then
        io.stderr:write(
            "install: missing operand\n"
        )
        os.exit(1)
    end

    for _,dir in ipairs(files) do
        mkdir_p(dir)
        set_mode(dir)

        if opts.verbose then
            print(
                "install: created directory '",
                dir,
                "'"
            )
        end
    end

    os.exit(0)
end


if opts.target then

    for _,src in ipairs(files) do

        local name =
            src:match("([^/]+)$")
            or src

        copy(
            src,
            opts.target .. "/" .. name
        )
    end

    os.exit(0)
end


if #files < 2 then
    io.stderr:write(
        "install: missing destination file operand\n"
    )
    os.exit(1)
end


local dest = files[#files]


if #files == 2 then

    if opts.create_dirs then
        local parent = dest:match("(.+)/[^/]+$")
        if parent then
            mkdir_p(parent)
        end
    end

    if is_dir(dest) and not opts.no_target then
        local name = files[1]:match("([^/]+)$") or files[1]
        copy(
            files[1],
            dest .. "/" .. name
        )
    else
        copy(
            files[1],
            dest
        )
    end

else

    for i=1,#files-1 do

        local src = files[i]

        local name =
            src:match("([^/]+)$")
            or src

        copy(
            src,
            dest .. "/" .. name
        )
    end
end
