local VERSION = "luajit-coreutils which 0.1"

local opts = {
    all = false,
    silent = false
}

local commands = {}


local function help()
    print([[
Usage: which [OPTION]... COMMAND...

Locate a command.

  -a, --all
         print all matches in PATH

  -s, --silent
         no output, only return status

      --skip-alias
         ignore aliases (compatibility option)

      --help
         display this help and exit
      --version
         output version information and exit
]])
end


local function executable(path)
    local f = io.open(path, "rb")

    if not f then
        return false
    end

    f:close()

    local result = os.execute(
        "[ -x " .. string.format("%q", path) .. " ]"
    )

    return result == true or result == 0
end


local function add_unique(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return
        end
    end

    tbl[#tbl + 1] = value
end


local function find_command(cmd)

    local found = {}

    -- If command contains /, do not search PATH
    if cmd:find("/", 1, true) then

        if executable(cmd) then
            found[#found + 1] = cmd
        end

        return found
    end


    local path = os.getenv("PATH") or ""

    for dir in (path .. ":"):gmatch("(.-):") do

        if dir == "" then
            dir = "."
        end

        local full = dir .. "/" .. cmd

        if executable(full) then
            add_unique(found, full)

            if not opts.all then
                break
            end
        end
    end


    return found
end


for _, arg in ipairs(arg) do

    if arg == "--help" then
        help()
        os.exit(0)

    elseif arg == "--version" then
        print(VERSION)
        os.exit(0)

    elseif arg == "-a" or arg == "--all" then
        opts.all = true

    elseif arg == "-s" or arg == "--silent" then
        opts.silent = true

    elseif arg == "--skip-alias" then
        -- compatibility with GNU which

    elseif arg:sub(1,1) == "-" then
        io.stderr:write(
            "which: invalid option -- '",
            arg,
            "'\n"
        )
        os.exit(2)

    else
        commands[#commands + 1] = arg
    end
end


if #commands == 0 then
    help()
    os.exit(1)
end


local failed = false


for _, cmd in ipairs(commands) do

    local result = find_command(cmd)

    if #result == 0 then
        failed = true
    else
        for _, path in ipairs(result) do
            if not opts.silent then
                print(path)
            end
        end
    end
end


if failed then
    os.exit(1)
end

os.exit(0)
