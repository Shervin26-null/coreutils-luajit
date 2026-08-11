local ffi = require("ffi")

ffi.cdef[[
char *getenv(const char *name);
int access(const char *pathname, int mode);
]]

local VERSION = "luajit-coreutils which 0.1"
local X_OK = 1

local function help()
print([[
Usage: which [OPTION]... COMMAND...

Locate a command.

  -a, --all       print all matching executables
      --help      display this help
      --version   output version information
]])
end

local all = false
local cmds = {}

for _, a in ipairs(arg) do
    if a == "--help" then
        help()
        os.exit(0)
    elseif a == "--version" then
        print(VERSION)
        os.exit(0)
    elseif a == "-a" or a == "--all" then
        all = true
    else
        cmds[#cmds + 1] = a
    end
end

if #cmds == 0 then
    io.stderr:write("which: missing command\n")
    os.exit(1)
end

local env = ffi.C.getenv("PATH")

if env == nil then
    os.exit(1)
end

local PATH = ffi.string(env)

local failed = false
local seen = {}
local seen = {}

local function search(cmd)
    local found = false

    if cmd:find("/") then
        if ffi.C.access(cmd, X_OK) == 0 then
            print(cmd)
            return true
        end
        return false
    end

    for dir in PATH:gmatch("[^:]+") do
        local file = dir .. "/" .. cmd

        if ffi.C.access(file, X_OK) == 0 then
            if not seen[file] then
                print(file)
                seen[file] = true
            end
            found = true

            if not all then
                break
            end
        end
    end

    return found
end

for _, cmd in ipairs(cmds) do
    if not search(cmd) then
        failed = true
    end
end

if failed then
    os.exit(1)
end
