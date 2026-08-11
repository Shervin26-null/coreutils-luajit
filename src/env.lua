local ffi = require("ffi")

ffi.cdef[[
extern char **environ;
int putenv(const char *string);
int unsetenv(const char *name);
]]

local function usage()
    io.write([[
Usage: env [OPTION]... [-] [NAME=VALUE]... [COMMAND [ARG]...]

Set each NAME to VALUE in the environment and run COMMAND.
]])
end

local args = {}
local vars = {}

local i = 1
while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        usage()
        os.exit(0)

    elseif a == "--version" then
        print("luajit-coreutils env 0.1")
        os.exit(0)

    elseif a:find("=", 1, true) then
        local name, value = a:match("^([^=]+)=(.*)$")
        vars[#vars + 1] = name .. "=" .. value

    else
        args[#args + 1] = a
    end

    i = i + 1
end

for _, v in ipairs(vars) do
    ffi.C.putenv(v)
end

if #args == 0 then
    local env = ffi.C.environ
    local i = 0

    while env[i] ~= nil do
        print(ffi.string(env[i]))
        i = i + 1
    end
else
    os.execute(table.concat(args, " "))
end
