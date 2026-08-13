local ffi = require("ffi")

local VERSION = "kill (coreutils-luajit) 0.1"

ffi.cdef[[
typedef int pid_t;

int kill(pid_t pid, int sig);
]]

local C = ffi.C

local signals = {
    HUP=1,
    INT=2,
    QUIT=3,
    KILL=9,
    TERM=15,
    STOP=19,
    CONT=18,
    USR1=10,
    USR2=12
}

local sig = 15
local quiet = false
local verbose = false
local pids = {}

local function usage()
    print([[
Usage: kill [OPTION]... PID...

Send a signal to processes.

  -s, --signal SIGNAL
  -SIGNAL
      --help
      --version
]])
end

local function parse_signal(s)
    return tonumber(s) or signals[s:upper()] or nil
end

local i = 1

while i <= #arg do
    local a = arg[i]

    if a == "--help" then
        usage()
        os.exit(0)

    elseif a == "--version" then
        print(VERSION)
        os.exit(0)

    elseif a == "-s" or a == "--signal" then
        i = i + 1
        sig = parse_signal(arg[i])

    elseif a:match("^%-%-signal=") then
        sig = parse_signal(a:match("=(.*)"))

    elseif a:match("^%-[A-Z]+$") then
        sig = parse_signal(a:sub(2))

    elseif a:match("^%-[0-9]+$") then
        sig = tonumber(a:sub(2))

    elseif a:match("^%-?%d+$") then
        pids[#pids+1] = tonumber(a)

    end

    i = i + 1
end

if not sig then
    io.stderr:write("kill: invalid signal\n")
    os.exit(1)
end

if #pids == 0 then
    io.stderr:write("kill: missing operand\n")
    os.exit(1)
end

local failed = false

for _, pid in ipairs(pids) do
    if C.kill(pid, sig) ~= 0 then
        io.stderr:write(
            "kill: failed to kill "..pid.."\n"
        )
        failed = true
    end
end

os.exit(failed and 1 or 0)
