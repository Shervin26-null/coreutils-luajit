local ffi = require("ffi")

ffi.cdef[[
    int system(const char *command);
    int remove(const char *filename);
]]

local C = ffi.C

-- Colors for visual test status
local COLOR_PASS = "\27[1;32mPASS\27[0m"
local COLOR_FAIL = "\27[1;31mFAIL\27[0m"
local COLOR_INFO = "\27[1;34m[TEST]\27[0m"

local total_tests = 0
local passed_tests = 0

-- Reads an entire file into a string
local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return "" end
    local content = f:read("*a")
    f:close()
    return content
end

-- Executes a command, redirecting output and status to temporary files
local function run_cmd(cmd)
    local stdout_file = "/tmp/_test_stdout.tmp"
    local stderr_file = "/tmp/_test_stderr.tmp"
    local status_file = "/tmp/_test_status.tmp"

    -- Construct shell command saving stdout, stderr, and exit code
    local full_cmd = string.format("( %s ) >%s 2>%s; echo $? > %s", cmd, stdout_file, stderr_file, status_file)
    C.system(full_cmd)

    local stdout = read_file(stdout_file)
    local stderr = read_file(stderr_file)
    local status = tonumber(read_file(status_file):match("%d+")) or 1

    C.remove(stdout_file)
    C.remove(stderr_file)
    C.remove(status_file)

    return {
        status = status,
        stdout = stdout,
        stderr = stderr
    }
end

-- Asserts parity between your Lua script and GNU coreutils
local function test(tool_name, args, stdin_data)
    total_tests = total_tests + 1

    -- Setup input pipe if stdin test data is provided
    local stdin_prefix = ""
    if stdin_data then
        stdin_prefix = string.format("printf %%s %q | ", stdin_data)
    end

    -- 1. Run standard GNU binary
    local gnu_cmd = string.format("%s%s %s", stdin_prefix, tool_name, args)
    local gnu_res = run_cmd(gnu_cmd)

    -- 2. Run your LuaJIT implementation
    local lua_cmd = string.format("%sluajit src/%s.lua %s", stdin_prefix, tool_name, args)
    local lua_res = run_cmd(lua_cmd)

    -- 3. Validate behavior parity
    local pass_status = (gnu_res.status == lua_res.status)
    local pass_stdout = (gnu_res.stdout == lua_res.stdout)
    
    -- Normalize error outputs (since program name in error strings like 'ls:' vs 'luajit:' can vary)
    local pass_stderr = (gnu_res.stderr == "" and lua_res.stderr == "") or (gnu_res.stderr ~= "" and lua_res.stderr ~= "")

    if pass_status and pass_stdout and pass_stderr then
        passed_tests = passed_tests + 1
        print(string.format("%s %-8s %s: '%s'", COLOR_PASS, "[" .. tool_name .. "]", "OK", args))
    else
        print(string.format("%s %-8s %s: '%s'", COLOR_FAIL, "[" .. tool_name .. "]", "FAILED", args))
        if not pass_status then
            print(string.format("   Exit status mismatch: Expected %d, got %d", gnu_res.status, lua_res.status))
        end
        if not pass_stdout then
            print("   --- Expected stdout ---")
            io.write(gnu_res.stdout)
            print("   --- Actual stdout ---")
            io.write(lua_res.stdout)
            print("   -----------------------")
        end
        if not pass_stderr then
            print("   --- Expected stderr presence ---")
            io.write(gnu_res.stderr)
            print("   --- Actual stderr presence ---")
            io.write(lua_res.stderr)
            print("   ------------------------------")
        end
    end
end

-- ============================================================================
-- SUITE TEST CASES
-- ============================================================================

print(COLOR_INFO .. " Starting LuaJIT Coreutils Validation Suite...\n")

-- 1. Test ls.lua
test("ls", "-1")
test("ls", "-la")
test("ls", "--non-existent-flag")

-- 2. Test cat.lua
test("cat", "a.txt")
test("cat", "-n a.txt")

-- 3. Test wc.lua
test("wc", "-l a.txt")
test("wc", "-w", "hello world from termux\nsecond line")

-- 4. Test head.lua & tail.lua
test("head", "-n 2 a.txt")
test("tail", "-n 2 a.txt")

-- 5. Test echo.lua & printenv.lua
test("echo", "Hello World")
test("echo", "-n NoNewline")
test("printenv", "HOME")

-- Final summary report
print(string.format("\n%s Finished! %d/%d tests passed.", COLOR_INFO, passed_tests, total_tests))
if passed_tests < total_tests then
    os.exit(1)
end
