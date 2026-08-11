local ffi = require("ffi")

ffi.cdef[[
int mkdir(const char *pathname, unsigned int mode);
int stat(const char *pathname, void *statbuf);
int chmod(const char *pathname, unsigned int mode);
int errno(void);
char *strerror(int errnum);
]]

local C = ffi.C

local VERSION = "luajit-coreutils mkdir 0.1"

local parents = false
local verbose = false
local mode = 493 -- 0755

local dirs = {}

local function perror(name)
	local e = ffi.errno()
	io.stderr:write("mkdir: cannot create directory '",
		name,
		"': ",
		ffi.string(C.strerror(e)),
		"\n")
end

local function exists(path)
	local buf = ffi.new("char[512]")
	return C.stat(path, buf) == 0
end

local function make_dir(path)
	if C.mkdir(path, mode) ~= 0 then
		return false
	end

	if verbose then
		print("mkdir: created directory '" .. path .. "'")
	end

	return true
end

local function mkdir_p(path)
	local current = ""

	for part in path:gmatch("[^/]+") do
		current = current == "" and part or current .. "/" .. part

		if not exists(current) then
			if not make_dir(current) then
				perror(current)
				return false
			end
		end
	end

	return true
end


local i = 1

while i <= #arg do
	local a = arg[i]

	if a == "--help" then
		io.write([[
Usage: mkdir [OPTION]... DIRECTORY...
Create the DIRECTORY(ies), if they do not already exist.

  -m, --mode=MODE   set file mode
  -p, --parents     no error if existing
  -v, --verbose     print a message for each created directory
      --help        display this help and exit
      --version     output version information and exit
]])
		os.exit(0)

	elseif a == "--version" then
		print(VERSION)
		os.exit(0)

	elseif a == "--" then
		for j = i + 1, #arg do
			dirs[#dirs + 1] = arg[j]
		end
		break

	elseif a == "-p" or a == "--parents" then
		parents = true

	elseif a == "-v" or a == "--verbose" then
		verbose = true

	elseif a:match("^%-m") then
		local m = a:match("^%-m=?(.+)")
		if not m then
			i = i + 1
			m = arg[i]
		end

		mode = tonumber(m, 8)

		if not mode then
			io.stderr:write("mkdir: invalid mode '", m, "'\n")
			os.exit(1)
		end

	elseif a:sub(1,1) == "-" then
		io.stderr:write("mkdir: invalid option '", a, "'\n")
		io.stderr:write("Try 'mkdir --help' for more information.\n")
		os.exit(1)

	else
		dirs[#dirs + 1] = a
	end

	i = i + 1
end


if #dirs == 0 then
	io.stderr:write("mkdir: missing operand\n")
	os.exit(1)
end


local failed = false

for _, d in ipairs(dirs) do
	if parents then
		if not mkdir_p(d) then
			failed = true
		end
	else
		if exists(d) then
			io.stderr:write("mkdir: cannot create directory '",
				d,
				"': File exists\n")
			failed = true
		elseif not make_dir(d) then
			perror(d)
			failed = true
		end
	end
end

if failed then
	os.exit(1)
end

os.exit(0)
