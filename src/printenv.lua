local ffi = require("ffi")

ffi.cdef[[
const char *getenv(const char *name);
extern char **environ;
]]

if #arg == 0 then
    local env = ffi.C.environ
    local i = 0

    while env[i] ~= nil do
        print(ffi.string(env[i]))
        i = i + 1
    end
else
    for _, name in ipairs(arg) do
        local value = ffi.C.getenv(name)

        if value ~= nil then
            print(ffi.string(value))
        end
    end
end
