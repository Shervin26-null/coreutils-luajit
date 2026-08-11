local VERSION = "luajit-coreutils cp 0.1"

local opts = {
    force = false,
    interactive = false,
    verbose = false,
    recursive = false,
    symlink = false,
}

local files = {}


local function help()
print([[
Usage: cp [OPTION]... SOURCE DEST
  or:  cp [OPTION]... SOURCE... DIRECTORY

Copy SOURCE to DEST.

  -f, --force
         overwrite existing files
  -i, --interactive
         prompt before overwrite
  -r, -R, --recursive
         copy directories recursively
  -s, --symbolic-link
         make symbolic links instead
  -v, --verbose
         explain what is being done

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

    elseif a == "-f" or a == "--force" then
        opts.force = true

    elseif a == "-i" or a == "--interactive" then
        opts.interactive = true

    elseif a == "-v" or a == "--verbose" then
        opts.verbose = true

    elseif a == "-r"
        or a == "-R"
        or a == "--recursive" then

        opts.recursive = true

    elseif a == "-s"
        or a == "--symbolic-link" then

        opts.symlink = true

    else
        files[#files+1] = a
    end
end


if #files < 2 then
    io.stderr:write("cp: missing destination file operand\n")
    os.exit(1)
end


local function exists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
        return true
    end
    return false
end


local function copy_file(src, dst)

    if exists(dst) then

        if opts.interactive then
            io.write("cp: overwrite '", dst, "'? ")
            local answer = io.read()

            if answer ~= "y"
            and answer ~= "Y" then
                return
            end

        elseif not opts.force then
            io.stderr:write(
                "cp: cannot overwrite '",
                dst,
                "'\n"
            )
            return
        end
    end


    if opts.symlink then

        os.remove(dst)

        local ok = os.execute(
            "ln -s " ..
            string.format("%q", src) ..
            " " ..
            string.format("%q", dst)
        )

        if not ok then
            io.stderr:write(
                "cp: failed to create symbolic link '",
                dst,
                "'\n"
            )
        end

    else

        local input = io.open(src, "rb")

        if not input then
            io.stderr:write(
                "cp: cannot open '",
                src,
                "'\n"
            )
            return
        end


        local output = io.open(dst, "wb")

        if not output then
            input:close()

            io.stderr:write(
                "cp: cannot create '",
                dst,
                "'\n"
            )
            return
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

    end


    if opts.verbose then
        print(
            src ..
            " -> " ..
            dst
        )
    end

end



local count = #files

if count == 2 then

    copy_file(
        files[1],
        files[2]
    )

else

    local dir = files[#files]

    for i = 1, count - 1 do

        local src = files[i]

        local name = src:match("([^/]+)$")
            or src

        copy_file(
            src,
            dir .. "/" .. name
        )
    end
end
