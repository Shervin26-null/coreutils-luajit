local ffi = require("ffi")

ffi.cdef[[
char *getcwd(char *buf, unsigned long size);
]]

local VERSION = "luajit-coreutils pwd 0.1"

local logical = true

for i = 1, #arg do
	local a = arg[i]

	if a == "--help" then
		print([[Usage: pwd [OPTION]...
Print the name of the current working directory.

  -L, --logical   use PWD from environment if possible
  -P, --physical  avoid all symlinks
      --help      display this help and exit
      --version   output version information and exit]])
		os.exit(0)

	elseif a == "--version" then
		print(VERSION)
		os.exit(0)

	elseif a == "-P" or a == "--physical" then
		logical = false

	elseif a == "-L" or a == "--logical" then
		logical = true

	else
		io.stderr:write("pwd: invalid option '", a, "'\n")
		os.exit(1)
	end
end

if logical then
	local env = os.getenv("PWD")

	if env and env ~= "" then
		print(env)
		os.exit(0)
	end
end

local buf = ffi.new("char[4096]")

if ffi.C.getcwd(buf, 4096) == nil then
	io.stderr:write("pwd: error retrieving current directory\n")
	os.exit(1)
end

print(ffi.string(buf))
