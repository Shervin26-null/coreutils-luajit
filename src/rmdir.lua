local VERSION = "luajit-coreutils rmdir 0.1"

local opts = {
    parents = false,
    verbose = false,
    ignore_nonempty = false
}

local dirs = {}

local function help()
    print([[
Usage: rmdir [OPTION]... DIRECTORY...

Remove empty directories.

  -p, --parents
         remove DIRECTORY and its ancestors
      --ignore-fail-on-non-empty
         ignore failures caused by non-empty directories
  -v, --verbose
         output diagnostics
      --help
         display help
      --version
         output version information
]])
end

local function remove_dir(path)
    local ok, err = os.remove(path)

    if not ok then
        if opts.ignore_nonempty then
            return true
        end

        io.stderr:write("rmdir: failed to remove '", path, "'\n")
        return false
    end

    if opts.verbose then
        print("rmdir: removing directory '" .. path .. "'")
    end

    return true
end

local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        help()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-p" or a == "--parents" then
        opts.parents = true

    elseif a == "-v" or a == "--verbose" then
        opts.verbose = true

    elseif a == "--ignore-fail-on-non-empty" then
        opts.ignore_nonempty = true

    else
        dirs[#dirs + 1] = a
    end

    i = i + 1
end

for _, dir in ipairs(dirs) do
    if opts.parents then
        while dir and dir ~= "." and dir ~= "/" do
            if not remove_dir(dir) then
                break
            end
            dir = dir:match("(.+)/[^/]+$") or "."
        end
    else
        remove_dir(dir)
    end
end
