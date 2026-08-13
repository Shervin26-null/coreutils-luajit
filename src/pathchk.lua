local VERSION = "pathchk (coreutils-luajit) 0.1"

local posix = false
local portable = false
local names = {}

local function help()
    print([[
Usage: pathchk [OPTION]... NAME...

Diagnose invalid or non-portable file names.

  -p     check for most POSIX systems
  -P     check for empty names and leading "-"
      --portability
         check for all POSIX systems
      --help
         display this help and exit
      --version
         output version information and exit
]])
end

local function fail(msg)
    io.stderr:write("pathchk: ", msg, "\n")
    return false
end

local function check_name(name)
    if name == "" then
        return fail("empty file name")
    end

    if portable and name:sub(1,1) == "-" then
        return fail("leading '-' in file name")
    end

    if posix then
        if #name > 14 then
            return fail("file name too long for POSIX")
        end

        for part in name:gmatch("[^/]+") do
            if #part > 14 then
                return fail("component too long: " .. part)
            end

            if part:find("[^A-Za-z0-9._-]") then
                return fail("non-portable character in: " .. part)
            end
        end
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

    elseif a == "-p" then
        posix = true

    elseif a == "-P" then
        portable = true

    elseif a == "--portability" then
        posix = true
        portable = true

    elseif a:sub(1,1) == "-" then
        io.stderr:write("pathchk: invalid option '", a, "'\n")
        os.exit(1)

    else
        names[#names+1] = a
    end

    i = i + 1
end


if #names == 0 then
    io.stderr:write("pathchk: missing operand\n")
    os.exit(1)
end


local ok = true

for _, name in ipairs(names) do
    if not check_name(name) then
        ok = false
    end
end

os.exit(ok and 0 or 1)
